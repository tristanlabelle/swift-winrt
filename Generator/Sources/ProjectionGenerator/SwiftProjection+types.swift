import DotNetMetadata
import WindowsMetadata
import CodeWriters

extension SwiftProjection {
    public func toType(_ type: TypeNode) throws -> SwiftType {
        switch type {
            case let .bound(type):
                if let specialTypeProjection = try getSpecialTypeProjection(type) {
                    return specialTypeProjection.swiftType
                }

                let swiftObjectType = SwiftType.identifier(
                    name: try toTypeName(type.definition),
                    genericArgs: try type.genericArgs.map { try toType($0) })
                return type.definition.isValueType ? swiftObjectType : .optional(wrapped: swiftObjectType)
            case let .genericParam(param):
                return .identifier(param.name)
            case let .array(of: element):
                return .array(element: try toType(element))
            default:
                fatalError("Not implemented: Swift representation of values of type \(type)")
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
                    swiftType: swiftType,
                    swiftDefaultValue: "[]",
                    projectionType: .chain(
                        .init("WindowsRuntime"),
                        .init("WinRTArrayProjection", genericArgs: [elementProjection.projectionType])),
                    kind: .array,
                    abiType: .chain(
                        .init("COM"),
                        .init("COMArray", genericArgs: [elementProjection.abiType])),
                    abiDefaultValue: ".null")

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
            swiftType: try toType(type.asNode),
            swiftDefaultValue: type.definition.isReferenceType ? "nil" : .defaultInitializer,
            projectionType: projectionType,
            kind: type.definition.isValueType ? .inert : .allocating,
            abiType: abiType,
            abiDefaultValue: type.definition.isReferenceType ? "nil" : .fromProjectionType)
    }

    private func getSpecialTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        if type.definition.assembly is Mscorlib {
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
        guard type.definition.namespace == "System",
                let systemType = WinRTSystemType(fromName: type.definition.name) else {
            return nil
        }

        switch systemType {
            case .boolean:
                return TypeProjection(
                    swiftType: .bool,
                    swiftDefaultValue: "false",
                    projectionType: .chain("COM", "Bool8Projection"),
                    kind: .inert,
                    abiType: .chain(abiModuleName, CAbi.boolName),
                    abiDefaultValue: "0")
            case .integer(.uint8): return .numeric(swiftType: .uint(bits: 8))
            case .integer(.int16): return .numeric(swiftType: .int(bits: 16))
            case .integer(.uint16): return .numeric(swiftType: .uint(bits: 16))
            case .integer(.int32): return .numeric(swiftType: .int(bits: 32))
            case .integer(.uint32): return .numeric(swiftType: .uint(bits: 32))
            case .integer(.int64): return .numeric(swiftType: .int(bits: 64))
            case .integer(.uint64): return .numeric(swiftType: .uint(bits: 64))
            case .float(double: false): return .numeric(swiftType: .float)
            case .float(double: true): return .numeric(swiftType: .double)
            case .char:
                return TypeProjection(
                    swiftType: .chain("Swift", "Unicode", "UTF16", "CodeUnit"),
                    swiftDefaultValue: "0",
                    projectionType: .chain("COM", "WideCharProjection"),
                    kind: .identity,
                    abiType: .chain("Swift", "UInt16"))
            case .guid:
                return TypeProjection(
                    swiftType: .chain("Foundation", "UUID"),
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: .chain("COM", "GUIDProjection"),
                    kind: .inert,
                    abiType: .chain(abiModuleName, CAbi.guidName))
            case .string:
                return .init(
                    swiftType: .string,
                    swiftDefaultValue: "\"\"",
                    projectionType: .chain("WindowsRuntime", "HStringProjection"),
                    kind: .allocating,
                    abiType: .optional(wrapped: .chain(abiModuleName, CAbi.hstringName)),
                    abiDefaultValue: "nil")
            case .object:
                return .init(
                    swiftType: .optional(wrapped: .chain("WindowsRuntime", "IInspectable")),
                    swiftDefaultValue: "nil",
                    projectionType: .chain("WindowsRuntime", "IInspectableProjection"),
                    kind: .allocating,
                    abiType: .optional(wrapped: .chain("IInspectableProjection", "COMPointer")),
                    abiDefaultValue: "nil")
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
                    swiftType: .chain("WindowsRuntime", "EventRegistrationToken"),
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: .chain("WindowsRuntime", "EventRegistrationToken"),
                    kind: .inert,
                    abiType: .chain(abiModuleName, CAbi.eventRegistrationTokenName),
                    abiDefaultValue: .defaultInitializer)

            case "HResult":
                return TypeProjection(
                    swiftType: .chain("COM", "HResult"),
                    swiftDefaultValue: .defaultInitializer,
                    projectionType: .chain("COM", "HResultProjection"),
                    kind: .inert,
                    abiType: .chain(abiModuleName, CAbi.hresultName),
                    abiDefaultValue: "0")

            default:
                return nil
        }
    }

    private func getIReferenceTypeProjection(of type: BoundType) throws -> TypeProjection? {
        if type.definition.namespace == "System",
                let _ = WinRTSystemType(fromName: type.definition.name) {
            let typeProjection = try getTypeProjection(type.asNode)
            return TypeProjection(
                swiftType: .optional(wrapped: typeProjection.swiftType),
                swiftDefaultValue: "nil",
                projectionType: .chain(
                    .init("WindowsRuntime"),
                    .init("IReferenceProjection"),
                    .init("Primitive", genericArgs: [ typeProjection.projectionType ])),
                kind: .allocating,
                abiDefaultValue: "nil")
        }

        return nil
    }
}