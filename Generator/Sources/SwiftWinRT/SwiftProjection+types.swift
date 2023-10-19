import DotNetMetadata
import CodeWriters

extension SwiftProjection {
    func toType(_ type: TypeNode) throws -> SwiftType {
        try getTypeProjection(type).swiftType
    }

    func toReturnType(_ type: TypeNode) throws -> SwiftType {
        let swiftType = try toType(type)
        if case .optional(let wrapped, implicitUnwrap: _) = swiftType {
            return referenceReturnNullability.applyTo(type: wrapped)
        }
        else {
            return swiftType
        }
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

    func getTypeProjection(_ type: TypeNode) throws -> TypeProjection {
        switch type {
            case let .bound(type):
                // Remap primitive types
                if type.definition.assembly is Mscorlib {
                    guard let typeProjection = getCoreLibraryTypeProjection(type) else {
                        fatalError("Not implemented: Projection for mscorlib \(type)")
                    }
                    return typeProjection
                }
                else if type.definition.namespace == "Windows.Foundation",
                        let typeProjection = try getWindowsFoundationTypeProjection(type) {
                    return typeProjection
                }

                let swiftTypeName = try toTypeName(type.definition)
                let swiftGenericArgs = try type.genericArgs.map { try toType($0) }
                let swiftObjectType = SwiftType.identifier(name: swiftTypeName, genericArgs: swiftGenericArgs)
                let swiftValueType = type.definition.isValueType ? swiftObjectType : .optional(wrapped: swiftObjectType)

                // Open generic types have no ABI representation
                guard !type.isParameterized else { return .noAbi(swiftType: swiftValueType) }

                // Only return ABI projections which we can currently produce
                guard type.definition is EnumDefinition
                    || type.definition is InterfaceDefinition
                    || type.definition is ClassDefinition else { return .noAbi(swiftType: swiftValueType) }

                var abiType = SwiftType.identifier(name: CAbi.mangleName(type: type))
                if type.definition.isReferenceType {
                    abiType = .optional(wrapped: abiType)
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
                    projectionType = swiftObjectType
                }

                return TypeProjection(
                    swiftType: swiftValueType,
                    projectionType: projectionType,
                    abiType: abiType,
                    inert: type.definition.isValueType)

            case let .genericParam(param):
                return .noAbi(swiftType: .identifier(name: param.name))

            case let .array(of: element):
                return .noAbi(swiftType: .array(element: try toType(element)))

            default:
                fatalError("Not implemented: projecting values of type \(type)")
        }
    }

    private func getCoreLibraryTypeProjection(_ type: BoundType) -> TypeProjection? {
        guard type.definition.namespace == "System" else { return nil }
        if type.genericArgs.isEmpty {
            switch type.definition.name {
                case "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Double":
                    return .numeric(
                        swiftType: type.definition.name,
                        abiType: type.definition.name.uppercased())

                case "Boolean":
                    return TypeProjection(
                        swiftType: .bool,
                        projectionType: .identifier(name: "BooleanProjection"),
                        abiType: .identifier(name: "boolean"),
                        defaultAbiValue: "0",
                        inert: true)
                case "SByte": return .numeric(swiftType: "Int8", abiType: "INT8")
                case "Byte": return .numeric(swiftType: "UInt8", abiType: "UINT8")
                case "IntPtr": return .numeric(swiftType: "Int", abiType: "INT_PTR")
                case "UIntPtr": return .numeric(swiftType: "UInt", abiType: "UINT_PTR")
                case "Single": return .numeric(swiftType: "Float", abiType: "FLOAT")
                case "Char": return .noAbi(swiftType: .identifierChain("UTF16", "CodeUnit"))
                case "Guid": return .noAbi(swiftType: .identifierChain("Foundation", "UUID"))
                case "String":
                    return .init(
                        swiftType: .string,
                        projectionType: .identifier(name: "HStringProjection"),
                        abiType: .optional(wrapped: .identifier(name: "HSTRING")),
                        defaultAbiValue: "nil")
                case "Object":
                    return .init(
                        swiftType: .optional(wrapped: .identifierChain("WindowsRuntime", "IInspectable")),
                        projectionType: .identifier(name: "IInspectableProjection"),
                        abiType: .optional(wrapped: .identifierChain("IInspectableProjection", "COMInterface")),
                        defaultAbiValue: "nil")
                case "Void":
                    return .noAbi(swiftType: .void)

                default: return nil
            }
        }
        else {
            return nil
        }
    }

    private func getWindowsFoundationTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        guard type.definition.namespace == "Windows.Foundation" else { return nil }
        switch type.definition.name {
            case "IReference`1":
                precondition(type.genericArgs.count == 1)
                let wrappedTypeProjection = try getTypeProjection(type.genericArgs[0])
                return TypeProjection.noAbi(swiftType: .optional(wrapped: wrappedTypeProjection.swiftType))

            case "HResult":
                return TypeProjection(
                    swiftType: .identifierChain("COM", "HResult"),
                    projectionType: .identifierChain("COM", "HResultProjection"),
                    abiType: .identifier(name: "HRESULT"),
                    defaultAbiValue: "S_OK",
                    inert: true)

            default:
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