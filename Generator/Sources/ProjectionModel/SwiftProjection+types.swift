import DotNetMetadata
import WindowsMetadata
import CodeWriters

extension SwiftProjection {
    public func toType(_ type: TypeNode) throws -> SwiftType {
        switch type {
            case let .bound(type):
                return try toType(type)
            case let .genericParam(param):
                return .identifier(param.name)
            case let .array(of: element):
                return .array(element: try toType(element))
            default:
                fatalError("Not implemented: Swift representation of values of type \(type)")
        }
    }

    public func toType(_ boundType: BoundType, nullable: Bool = true) throws -> SwiftType {
        if let specialTypeProjection = try getSpecialTypeProjection(boundType) {
            return specialTypeProjection.swiftType
        }

        let swiftObjectType = SwiftType.identifier(
            name: try toTypeName(boundType.definition),
            genericArgs: try boundType.genericArgs.map { try toType($0) })
        return boundType.definition.isReferenceType && nullable ? .optional(wrapped: swiftObjectType) : swiftObjectType
    }

    public func isProjectionInert(_ typeDefinition: TypeDefinition) throws -> Bool {
        switch typeDefinition {
            case is InterfaceDefinition, is DelegateDefinition, is ClassDefinition: return false
            case let structDefinition as StructDefinition:
                return try structDefinition.fields.allSatisfy { field in
                    guard field.isInstance else { return true }
                    switch try field.type {
                        case let .bound(type):
                            // Careful, primitive types have recursive fields (System.Int32 has a field of type System.Int32)
                            return try type.definition == typeDefinition || isProjectionInert(type.definition)
                        default: return false
                    }
                }
            case is EnumDefinition: return true
            default: fatalError()
        }
    }

    public func isNullAsErrorEligible(_ type: TypeNode) -> Bool {
        switch type {
            case let .bound(type):
                return type.definition.isReferenceType
                    && type.definition.fullName != "System.String"
                    && type.definition.fullName != "Windows.Foundation.IReference`1"
            default:
                return false
        }
    }

    public func toReturnType(_ type: TypeNode, typeGenericArgs: [TypeNode]? = nil) throws -> SwiftType {
        let swiftType = try toType(type.bindGenericParams(typeArgs: typeGenericArgs))
        return isNullAsErrorEligible(type) ? swiftType.unwrapOptional() : swiftType
    }

    public func getTypeProjection(_ type: TypeNode) throws -> TypeProjection {
        switch type {
            case let .bound(type):
                return try getTypeProjection(type)
            case let .genericParam(param):
                throw UnexpectedTypeError(param.name, context: "Generic params have no projection.")
            case let .array(of: element):
                let elementProjection = try getTypeProjection(element)
                let swiftType = SwiftType.array(element: elementProjection.swiftType)
                return TypeProjection(
                    abiType: SupportModules.COM.comArray(of: elementProjection.abiType),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: swiftType,
                    swiftDefaultValue: "[]",
                    projectionType: SupportModules.WinRT.arrayProjection(of: elementProjection.projectionType),
                    kind: .array)

            default:
                fatalError("Not implemented: projecting values of type \(type)")
        }
    }

    private func getTypeProjection(_ type: BoundType) throws -> TypeProjection {
        if let specialTypeProjection = try getSpecialTypeProjection(type) {
            return specialTypeProjection
        }

        var abiType: SwiftType
        if let classDefinition = type.definition as? ClassDefinition {
            // The ABI type for classes is that of their default interface
            guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else {
                throw WinMDError.missingAttribute
            }
            abiType = SwiftType.identifier(name: try CAbi.mangleName(type: defaultInterface.asBoundType))
        }
        else {
            abiType = SwiftType.identifier(name: try CAbi.mangleName(type: type))
        }

        if type.definition.isReferenceType {
            abiType = .optional(wrapped: .unsafeMutablePointer(to: abiType))
        }

        let projectionType: SwiftType = try {
            let projectionTypeName = try toProjectionTypeName(type.definition)
            if type.genericArgs.isEmpty {
                return .identifier(projectionTypeName)
            }
            else {
                return .chain([
                    .init(projectionTypeName),
                    .init(try SwiftProjection.toProjectionInstantiationTypeName(genericArgs: type.genericArgs))
                ])
            }
        }()

        return TypeProjection(
            abiType: abiType,
            abiDefaultValue: type.definition.isReferenceType ? "nil" : .defaultInitializer,
            swiftType: try toType(type.asNode),
            swiftDefaultValue: type.definition.isReferenceType ? "nil" : .defaultInitializer,
            projectionType: projectionType,
            kind: try isProjectionInert(type.definition) ? .inert : .allocating)
    }

    private func getSpecialTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        if type.definition.namespace == "System" {
            guard let typeProjection = try getCoreLibraryTypeProjection(type) else {
                throw UnexpectedTypeError(type.description, context: "Not a valid WinRT System type.")
            }
            return typeProjection
        }
        else if type.definition.namespace == "Windows.Foundation",
                let typeProjection = try getWindowsFoundationTypeProjection(type) {
            return typeProjection
        }
        else {
            return nil
        }
    }

    private func getCoreLibraryTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        guard type.definition.namespace == "System" else { return nil }

        if type.definition.name == "Object" {
            return .init(
                abiType: .optional(wrapped: SupportModules.WinRT.iinspectablePointer),
                abiDefaultValue: .nil,
                swiftType: .optional(wrapped: SupportModules.WinRT.iinspectable),
                swiftDefaultValue: .nil,
                projectionType: SupportModules.WinRT.iinspectableProjection,
                kind: .allocating)
        }
        guard let primitiveType = WinRTPrimitiveType(fromSystemNamespaceType: type.definition.name) else { return nil }

        switch primitiveType {
            // Identity projections
            case .boolean, .integer(_), .float(_):
                let swiftType = primitiveType == .boolean ? SwiftType.bool
                    : primitiveType == .float(double: false) ? SwiftType.float
                    : SwiftType.chain("Swift", primitiveType.name)
                return TypeProjection(
                    abiType: swiftType,
                    abiDefaultValue: primitiveType == .boolean ? .`false` : .zero,
                    swiftType: swiftType,
                    swiftDefaultValue: primitiveType == .boolean ? .`false` : .zero,
                    projectionType: SupportModules.WinRT.primitiveProjection(of: primitiveType),
                    kind: .identity)
            case .char16:
                return TypeProjection(
                    abiType: .chain("Swift", "UInt16"),
                    abiDefaultValue: .zero,
                    swiftType: SupportModules.WinRT.char16,
                    swiftDefaultValue: ".init(0)",
                    projectionType: SupportModules.WinRT.primitiveProjection(of: primitiveType),
                    kind: .inert)
            case .guid:
                return TypeProjection(
                    abiType: .chain(abiModuleName, CAbi.guidName),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: SupportModules.COM.guid,
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: SupportModules.WinRT.primitiveProjection(of: primitiveType),
                    kind: .inert)
            case .string:
                return .init(
                    abiType: .optional(wrapped: .chain(abiModuleName, CAbi.hstringName)),
                    abiDefaultValue: .nil,
                    swiftType: .string,
                    swiftDefaultValue: .emptyString,
                    projectionType: SupportModules.WinRT.primitiveProjection(of: primitiveType),
                    kind: .allocating)
        }
    }

    private func getWindowsFoundationTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        guard type.definition.namespace == "Windows.Foundation" else { return nil }
        switch type.definition.name {
            case "IReference`1":
                guard case let .bound(type) = type.genericArgs[0] else { return nil }
                return try getIReferenceTypeProjection(of: type)

            case "EventRegistrationToken":
                return TypeProjection(
                    abiType: .chain(abiModuleName, CAbi.eventRegistrationTokenName),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: SupportModules.WinRT.eventRegistrationToken,
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: SupportModules.WinRT.eventRegistrationToken,
                    kind: .inert)

            case "HResult":
                return TypeProjection(
                    abiType: .chain(abiModuleName, CAbi.hresultName),
                    abiDefaultValue: .zero,
                    swiftType: SupportModules.COM.hresult,
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: SupportModules.COM.hresultProjection,
                    kind: .inert)

            default:
                return nil
        }
    }

    private func getIReferenceTypeProjection(of type: BoundType) throws -> TypeProjection? {
        let typeProjection = try getTypeProjection(type.asNode)
        let projectionType: SwiftType
        if type.definition.namespace == "System",
                let primitiveType = WinRTPrimitiveType(fromSystemNamespaceType: type.definition.name) {
            projectionType = SupportModules.WinRT.ireferenceUnboxingProjection(of: primitiveType)
        }
        else if type.definition is EnumDefinition || type.definition is StructDefinition || type.definition is DelegateDefinition {
            projectionType = SupportModules.WinRT.ireferenceUnboxingProjection(of: typeProjection.projectionType)
        }
        else {
            return nil
        }

        return TypeProjection(
            abiType: .optional(wrapped: .unsafeMutablePointer(to: .chain(abiModuleName, CAbi.ireferenceName))),
            abiDefaultValue: .nil,
            swiftType: .optional(wrapped: typeProjection.swiftType),
            swiftDefaultValue: .nil,
            projectionType: projectionType,
            kind: .allocating)
    }
}