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
                guard !(type.definition is DelegateDefinition) else { return .noAbi(swiftType: swiftValueType) }

                var abiType = SwiftType.identifier(name: try CAbi.mangleName(type: type))
                if type.definition.isReferenceType {
                    abiType = .optional(wrapped: .identifier("UnsafeMutablePointer", genericArgs: [abiType]))
                }

                let projectionType: SwiftType
                if type.definition is InterfaceDefinition || type.definition is DelegateDefinition {
                    // Interfaces and delegates have an accompanying ABIProjection-conforming class
                    if type.genericArgs.isEmpty {
                        projectionType = .identifier(swiftTypeName + "Projection")
                    }
                    else {
                        projectionType = .chain([
                            .init(swiftTypeName + "Projection"),
                            .init(try toProjectionInstanciationTypeName(genericArgs: type.genericArgs))
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
                    abiDefaultValue: type.definition.isReferenceType ? "nil" : nil,
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
                case "Boolean":
                    return TypeProjection(
                        swiftType: .bool,
                        projectionType: .chain("COM", "BooleanProjection"),
                        abiType: .identifier("boolean"),
                        abiDefaultValue: "0",
                        inert: true)
                case "SByte": return .numeric(swiftType: .int(bits: 8), abiType: "INT8")
                case "Byte": return .numeric(swiftType: .uint(bits: 8), abiType: "UINT8")
                case "Int16": return .numeric(swiftType: .int(bits: 16), abiType: "INT16")
                case "UInt16": return .numeric(swiftType: .uint(bits: 16), abiType: "UINT16")
                case "Int32": return .numeric(swiftType: .int(bits: 32), abiType: "INT32")
                case "UInt32": return .numeric(swiftType: .uint(bits: 32), abiType: "UINT32")
                case "Int64": return .numeric(swiftType: .int(bits: 64), abiType: "INT64")
                case "UInt64": return .numeric(swiftType: .uint(bits: 64), abiType: "UINT64")
                case "IntPtr": return .numeric(swiftType: .int, abiType: "INT_PTR")
                case "UIntPtr": return .numeric(swiftType: .uint, abiType: "UINT_PTR")
                case "Single": return .numeric(swiftType: .float, abiType: "FLOAT")
                case "Double": return .numeric(swiftType: .double, abiType: "DOUBLE")
                case "Char":
                    return TypeProjection(
                        swiftType: .chain("COM", "WideChar"),
                        projectionType: .chain("COM", "WideChar"),
                        abiType: .identifier("WCHAR"),
                        abiDefaultValue: "0",
                        inert: true)
                case "Guid":
                    return TypeProjection(
                        swiftType: .chain("Foundation", "UUID"),
                        projectionType: .chain("COM", "GUIDProjection"),
                        abiType: .identifier("GUID"),
                        inert: true)
                case "String":
                    return .init(
                        swiftType: .string,
                        projectionType: .identifier("HStringProjection"),
                        abiType: .optional(wrapped: .identifier("HSTRING")),
                        abiDefaultValue: "nil")
                case "Object":
                    return .init(
                        swiftType: .optional(wrapped: .chain("WindowsRuntime", "IInspectable")),
                        projectionType: .identifier("IInspectableProjection"),
                        abiType: .optional(wrapped: .chain("IInspectableProjection", "COMPointer")),
                        abiDefaultValue: "nil")
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
                    swiftType: .chain("COM", "HResult"),
                    projectionType: .chain("COM", "HResultProjection"),
                    abiType: .identifier("HRESULT"),
                    abiDefaultValue: "S_OK",
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