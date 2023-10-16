import DotNetMetadata
import CodeWriters

extension SwiftProjection {
    func toType(_ type: TypeNode, referenceNullability: ReferenceNullability = .explicit) throws -> SwiftType {
        try getTypeProjection(type, referenceNullability: referenceNullability).swiftType
    }

    func toReturnType(_ type: TypeNode) throws -> SwiftType {
        try toType(type, referenceNullability: referenceReturnNullability)
    }

    func toReturnTypeUnlessVoid(_ type: TypeNode) throws -> SwiftType? {
        if case let .bound(type) = type,
            let mscorlib = type.definition.assembly as? Mscorlib,
            type.definition === mscorlib.specialTypes.void { return nil }
        return try toType(type)
    }

    func toAbiType(_ type: BoundType, referenceNullability: ReferenceNullability) -> SwiftType {
        referenceNullability.applyTo(type:
            .identifierChain(abiModuleName, CAbi.mangleName(type: type)))
    }

    func toAbiVTableType(_ type: BoundType, referenceNullability: ReferenceNullability) -> SwiftType {
        guard type.definition is InterfaceDefinition else { fatalError("\(type) has no VTable") }
        return referenceNullability.applyTo(type:
            .identifierChain(abiModuleName, CAbi.mangleName(type: type) + CAbi.interfaceVTableSuffix))
    }

    func getTypeProjection(_ type: TypeNode, referenceNullability: ReferenceNullability = .explicit) throws -> TypeProjection {
        switch type {
            case let .bound(type):
                // Remap primitive types
                if type.definition.assembly is Mscorlib {
                    guard let result = Self.getTypeProjection(mscorlibType: type, referenceNullability: referenceNullability) else {
                        fatalError("Not implemented: Unknown Mscorlib type projection")
                    }
                    return result
                }
                else if Self.tryGetIReferenceType(type) != nil {
                    fatalError("Not implemented: IReference<T> projection")
                }

                let swiftTypeName = try toTypeName(type.definition)
                let swiftGenericArgs = try type.genericArgs.map { try toType($0) }
                var swiftType = SwiftType.identifier(name: swiftTypeName, genericArgs: swiftGenericArgs)
                if type.definition.isReferenceType {
                    swiftType = referenceNullability.applyTo(type: swiftType)
                }

                // Open generic types have no ABI representation
                guard !type.isParameterized else { return .init(swiftType: swiftType) }

                // Only return projections which we can currently produce
                guard type.definition is EnumDefinition || type.definition is InterfaceDefinition else { return .init(swiftType: swiftType) }

                var abiType = SwiftType.identifier(name: CAbi.mangleName(type: type))
                if type.definition.isReferenceType {
                    abiType = referenceNullability.applyTo(type: abiType)
                }

                let projectionType: SwiftType
                if type.definition is InterfaceDefinition || type.definition is DelegateDefinition {
                    // Interfaces and delegates have an accompanying ABIProjection-conforming class
                    if type.genericArgs.isEmpty {
                        projectionType = .identifier(name: swiftTypeName + "Projection")
                    }
                    else {
                        projectionType = .identifierChain([
                            .init(swiftTypeName + "Projection", genericArgs: swiftGenericArgs),
                            .init("Instance")
                        ])
                    }
                }
                else {
                    // Structs, enums and classes conform to ABIProjection directly and cannot be generic
                    projectionType = swiftType
                }

                return .init(
                    swiftType: swiftType,
                    abiType: abiType,
                    projectionType: projectionType,
                    inert: type.definition.isValueType)

            case let .genericParam(param):
                return .init(swiftType: .identifier(name: param.name))

            case let .array(of: element):
                // TODO: implement ABI projection
                return .init(swiftType: .array(element: try toType(element)))

            default:
                fatalError("Not implemented: projecting values of type \(type)")
        }
    }

    private static func getTypeProjection(mscorlibType: BoundType, referenceNullability: ReferenceNullability) -> TypeProjection? {
        guard mscorlibType.definition.namespace == "System" else { return nil }
        if mscorlibType.genericArgs.isEmpty {
            switch mscorlibType.definition.name {
                case "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Double":
                    return .init(
                        swiftType: .identifier(name: mscorlibType.definition.name),
                        abiType: .identifier(name: mscorlibType.definition.name.uppercased()))

                case "Boolean":
                    return .init(
                        swiftType: .bool,
                        abiType: .identifier(name: "boolean"),
                        projectionType: .identifier(name: "BooleanProjection"))
                case "SByte":
                    return .init(
                        swiftType: .int(bits: 8, signed: true),
                        abiType: .identifier(name: "INT8"))
                case "Byte":
                    return .init(
                        swiftType: .int(bits: 8, signed: false),
                        abiType: .identifier(name: "UINT8"))
                case "IntPtr":
                    return .init(
                        swiftType: .int,
                        abiType: .identifier(name: "INT_PTR"))
                case "UIntPtr":
                    return .init(
                        swiftType: .uint,
                        abiType: .identifier(name: "UINT_PTR"))
                case "Single":
                    return .init(
                        swiftType: .float,
                        abiType: .identifier(name: "FLOAT"))
                case "Char":
                    return .init(
                        swiftType: .identifierChain("UTF16", "CodeUnit"),
                        abiType: .identifier(name: "WCHAR"))
                case "Guid":
                    // TODO: Provide GUID -> UUID Projection
                    return .init(
                        swiftType: .identifierChain("Foundation", "UUID"))
                case "String":
                    return .init(
                        swiftType: .string,
                        abiType: .optional(wrapped: .identifier(name: "HSTRING")),
                        projectionType: .identifier(name: "HStringProjection"))
                case "Object":
                    return .init(
                        swiftType: referenceNullability.applyTo(type: .identifierChain("WindowsRuntime", "IInspectable")),
                        projectionType: .identifier(name: "IInspectableProjection"))
                case "Void":
                    return .init(swiftType: .void)

                default: return nil
            }
        }
        else {
            return nil
        }
    }

    private static func tryGetIReferenceType(_ type: BoundType) -> TypeNode? {
        guard type.definition.assembly.name == "Windows",
            type.definition.assembly.version == .all255,
            type.definition.namespace == "Windows.Foundation",
            type.definition.name == "IReference`1",
            type.genericArgs.count == 1 else { return nil }
        return type.genericArgs[0]
    }
}