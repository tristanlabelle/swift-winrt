import DotNetMetadata
import WindowsMetadata
import CodeWriters

extension Projection {
    public func toTypeExpression(_ type: TypeNode, outerNullable: Bool = true) throws -> SwiftType {
        switch type {
            case let .bound(boundType):
                if let specialTypeBinding = try getSpecialTypeBinding(boundType) {
                    if boundType.definition.namespace == "System", boundType.definition.name == "Object", !outerNullable {
                        return specialTypeBinding.swiftType.unwrapOptional()
                    }
                    return specialTypeBinding.swiftType
                }

                let swiftType = try SwiftType.named(
                    toTypeName(boundType.definition),
                    genericArgs: boundType.genericArgs.map { try toTypeExpression($0) })
                return boundType.definition.isReferenceType && outerNullable ? swiftType.optional() : swiftType
            case let .genericParam(param):
                return .named(param.name)
            case let .array(of: element):
                return .array(element: try toTypeExpression(element))
            default:
                fatalError("Not implemented: Swift representation of values of type \(type)")
        }
    }

    public func toTypeReference(_ boundType: BoundType) throws -> SwiftType {
        // getSpecialTypeBinding returns a type expression, which includes the optional wrapping.
        if let specialTypeBinding = try getSpecialTypeBinding(boundType) {
            return specialTypeBinding.swiftType.unwrapOptional()
        }

        return .named(
            try toTypeName(boundType.definition),
            genericArgs: try boundType.genericArgs.map { try toTypeExpression($0) })
    }

    public func isPODBinding(_ typeDefinition: TypeDefinition) throws -> Bool {
        switch typeDefinition {
            case is InterfaceDefinition, is DelegateDefinition, is ClassDefinition: return false
            case let structDefinition as StructDefinition:
                return try structDefinition.fields.allSatisfy { field in
                    guard field.isInstance else { return true }
                    switch try field.type {
                        case let .bound(type):
                            // Careful, primitive types have recursive fields (System.Int32 has a field of type System.Int32)
                            return try type.definition == typeDefinition || isPODBinding(type.definition)
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

    public func isSwiftEnumEligible(_ enumDefinition: EnumDefinition) throws -> Bool {
        try enumDefinition.attributes.contains(where: { try $0.type.name == "SwiftEnumAttribute" }) && !enumDefinition.isFlags
    }

    public func toReturnType(_ type: TypeNode) throws -> SwiftType {
        try toTypeExpression(type, outerNullable: !isNullAsErrorEligible(type))
    }

    public func getTypeBinding(_ type: TypeNode) throws -> TypeBinding {
        switch type {
            case let .bound(type):
                return try getTypeBinding(type)
            case let .genericParam(param):
                throw UnexpectedTypeError(param.name, context: "Generic params have no binding.")
            case let .array(of: element):
                let elementBinding = try getTypeBinding(element)
                let swiftType = SwiftType.array(element: elementBinding.swiftType)
                return TypeBinding(
                    abiType: SupportModules.COM.comArray(of: elementBinding.abiType),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: swiftType,
                    swiftDefaultValue: "[]",
                    bindingType: SupportModules.WinRT.arrayBinding(of: elementBinding.bindingType),
                    kind: .array)

            default:
                fatalError("Not implemented: type binding for values of type \(type)")
        }
    }

    private func getTypeBinding(_ type: BoundType) throws -> TypeBinding {
        if let specialTypeBinding = try getSpecialTypeBinding(type) {
            return specialTypeBinding
        }

        var abiType: SwiftType
        if let classDefinition = type.definition as? ClassDefinition {
            // The ABI type for classes is that of their default interface
            guard let defaultInterface = try DefaultAttribute.getDefaultInterface(classDefinition) else {
                throw WinMDError.missingAttribute
            }
            abiType = .named(try CAbi.mangleName(type: defaultInterface.asBoundType))
        }
        else {
            abiType = .named(try CAbi.mangleName(type: type))
        }

        if type.definition.isReferenceType {
            abiType = .unsafeMutablePointer(pointee: abiType).optional()
        }

        return TypeBinding(
            abiType: abiType,
            abiDefaultValue: type.definition.isReferenceType ? "nil" : .defaultInitializer,
            swiftType: try toTypeExpression(type.asNode),
            swiftDefaultValue: type.definition.isReferenceType ? "nil" : .defaultInitializer,
            bindingType: try toBindingType(type),
            kind: try isPODBinding(type.definition) ? .pod : .allocating)
    }

    private func getSpecialTypeBinding(_ type: BoundType) throws -> TypeBinding? {
        if type.definition.namespace == "System" {
            guard let typeBinding = try getCoreLibraryTypeBinding(type) else {
                throw UnexpectedTypeError(type.description, context: "Not a valid WinRT System type.")
            }
            return typeBinding
        }
        else if type.definition.namespace == "Windows.Foundation",
                let typeBinding = try getWindowsFoundationTypeBinding(type) {
            return typeBinding
        }
        else {
            return nil
        }
    }

    private func getCoreLibraryTypeBinding(_ type: BoundType) throws -> TypeBinding? {
        guard type.definition.namespace == "System" else { return nil }

        if type.definition.name == "Object" {
            return .init(
                abiType: SupportModules.WinRT.iinspectablePointer.optional(),
                abiDefaultValue: .nil,
                swiftType: SupportModules.WinRT.iinspectable.optional(),
                swiftDefaultValue: .nil,
                bindingType: SupportModules.WinRT.iinspectableBinding,
                kind: .allocating)
        }
        guard let primitiveType = WinRTPrimitiveType(fromSystemNamespaceType: type.definition.name) else { return nil }

        switch primitiveType {
            // Identity projections
            case .boolean, .integer(_), .float(_):
                // These have the same name between .NET and Swift, except for Bool and Float
                let swiftType: SwiftType = primitiveType == .boolean ? .bool
                    : primitiveType == .float(double: false) ? .float
                    : .swift(primitiveType.name)
                return TypeBinding(
                    abiType: swiftType,
                    abiDefaultValue: primitiveType == .boolean ? .`false` : .zero,
                    swiftType: swiftType,
                    swiftDefaultValue: primitiveType == .boolean ? .`false` : .zero,
                    bindingType: SupportModules.WinRT.primitiveBinding(of: primitiveType),
                    kind: .identity)
            case .char16:
                return TypeBinding(
                    abiType: .swift("UInt16"),
                    abiDefaultValue: .zero,
                    swiftType: SupportModules.WinRT.char16,
                    swiftDefaultValue: ".init(0)",
                    bindingType: SupportModules.WinRT.primitiveBinding(of: primitiveType),
                    kind: .pod)
            case .guid:
                return TypeBinding(
                    abiType: .named(CAbi.guidName),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: SupportModules.COM.guid,
                    swiftDefaultValue: .defaultInitializer,
                    bindingType: SupportModules.WinRT.primitiveBinding(of: primitiveType),
                    kind: .pod)
            case .string:
                return .init(
                    abiType: .named(CAbi.hstringName).optional(),
                    abiDefaultValue: .nil,
                    swiftType: .string,
                    swiftDefaultValue: .emptyString,
                    bindingType: SupportModules.WinRT.primitiveBinding(of: primitiveType),
                    kind: .allocating)
        }
    }

    private func getWindowsFoundationTypeBinding(_ type: BoundType) throws -> TypeBinding? {
        guard type.definition.namespace == "Windows.Foundation" else { return nil }
        switch type.definition.name {
            case "IReference`1":
                guard case let .bound(type) = type.genericArgs[0] else { return nil }
                return try getIReferenceTypeBinding(of: type)

            case "EventRegistrationToken":
                return TypeBinding(
                    abiType: .named(CAbi.eventRegistrationTokenName),
                    abiDefaultValue: .defaultInitializer,
                    swiftType: SupportModules.WinRT.eventRegistrationToken,
                    swiftDefaultValue: .defaultInitializer,
                    bindingType: SupportModules.WinRT.eventRegistrationToken,
                    kind: .pod)

            case "HResult":
                return TypeBinding(
                    abiType: .named(CAbi.hresultName),
                    abiDefaultValue: .zero,
                    swiftType: SupportModules.COM.hresult,
                    swiftDefaultValue: .defaultInitializer,
                    bindingType: SupportModules.COM.hresultBinding,
                    kind: .pod)

            default:
                return nil
        }
    }

    private func getIReferenceTypeBinding(of type: BoundType) throws -> TypeBinding? {
        let typeBinding = try getTypeBinding(type.asNode)
        let bindingType: SwiftType
        if type.definition.namespace == "System",
                let primitiveType = WinRTPrimitiveType(fromSystemNamespaceType: type.definition.name) {
            bindingType = SupportModules.WinRT.ireferenceToOptionalBinding(of: primitiveType)
        }
        else if type.definition is EnumDefinition || type.definition is StructDefinition || type.definition is DelegateDefinition {
            bindingType = SupportModules.WinRT.ireferenceToOptionalBinding(of: typeBinding.bindingType)
        }
        else {
            return nil
        }

        return TypeBinding(
            abiType: .unsafeMutablePointer(pointee: .named(CAbi.ireferenceName)).optional(),
            abiDefaultValue: .nil,
            swiftType: typeBinding.swiftType.optional(),
            swiftDefaultValue: .nil,
            bindingType: bindingType,
            kind: .allocating)
    }
}