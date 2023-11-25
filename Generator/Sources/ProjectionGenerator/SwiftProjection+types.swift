import DotNetMetadata
import WindowsMetadata
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
                            .init(try SwiftProjection.toProjectionInstanciationTypeName(genericArgs: type.genericArgs))
                        ])
                    }
                }
                else {
                    // Structs, enums and classes conform to ABIProjection directly and cannot be generic
                    projectionType = swiftObjectType
                }

                return TypeProjection(
                    swiftType: swiftValueType,
                    abiType: abiType,
                    projectionType: projectionType,
                    abiDefaultValue: type.definition.isReferenceType ? "nil" : nil,
                    abiKind: type.definition.isValueType ? .inert : .allocating)

            case let .genericParam(param):
                return .noAbi(swiftType: .identifier(name: param.name))

            case let .array(of: element):
                let elementProjection = try getTypeProjection(element)
                if let elementProjectionAbi = elementProjection.abi {
                    return TypeProjection(
                        swiftType: .array(element: elementProjection.swiftType),
                        abiType: .chain(
                            .init("COM"),
                            .init("COMArray", genericArgs: [elementProjectionAbi.type])),
                        projectionType: .chain(
                            .init("WindowsRuntime"),
                            .init("WinRTArrayProjection", genericArgs: [elementProjectionAbi.projectionType])),
                        abiDefaultValue: ".null",
                        abiKind: .array)
                }
                else {
                    return .noAbi(swiftType: .array(element: elementProjection.swiftType))
                }

            default:
                fatalError("Not implemented: projecting values of type \(type)")
        }
    }

    private func getCoreLibraryTypeProjection(_ type: BoundType) -> TypeProjection? {
        guard type.definition.namespace == "System" else { return nil }
        guard let systemType = WinRTSystemType(fromName: type.definition.name) else { return nil }
        switch systemType {
            case .boolean:
                return TypeProjection(
                    swiftType: .bool,
                    abiType: .int(bits: 8, signed: false),
                    projectionType: .chain("COM", "BooleanProjection"),
                    abiDefaultValue: "0",
                    abiKind: .inert)
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
                    swiftType: .chain("COM", "WideChar"),
                    abiType: .chain(abiModuleName, "char16_t"),
                    projectionType: .chain("COM", "WideChar"),
                    abiDefaultValue: "0",
                    abiKind: .inert)
            case .guid:
                return TypeProjection(
                    swiftType: .chain("Foundation", "UUID"),
                    abiType: .chain(abiModuleName, CAbi.guidName),
                    projectionType: .chain("COM", "GUIDProjection"),
                    abiKind: .inert)
            case .string:
                return .init(
                    swiftType: .string,
                    abiType: .optional(wrapped: .chain(abiModuleName, CAbi.hstringName)),
                    projectionType: .chain("WindowsRuntime", "HStringProjection"),
                    abiDefaultValue: "nil",
                    abiKind: .allocating)
            case .object:
                return .init(
                    swiftType: .optional(wrapped: .chain("WindowsRuntime", "IInspectable")),
                    abiType: .optional(wrapped: .chain("IInspectableProjection", "COMPointer")),
                    projectionType: .chain("WindowsRuntime", "IInspectableProjection"),
                    abiDefaultValue: "nil",
                    abiKind: .allocating)
        }
    }

    private func getWindowsFoundationTypeProjection(_ type: BoundType) throws -> TypeProjection? {
        guard type.definition.namespace == "Windows.Foundation" else { return nil }
        switch type.definition.name {
            case "IReference`1":
                precondition(type.genericArgs.count == 1)
                let wrappedTypeProjection = try getTypeProjection(type.genericArgs[0])
                // TODO(#6): Implement IReference<T> projection
                return TypeProjection.noAbi(swiftType: .optional(wrapped: wrappedTypeProjection.swiftType))

            case "EventRegistrationToken":
                return TypeProjection(
                    swiftType: .chain("WindowsRuntime", "EventRegistrationToken"),
                    abiType: .chain(abiModuleName, CAbi.eventRegistrationTokenName),
                    projectionType: .chain("WindowsRuntime", "EventRegistrationToken"),
                    abiDefaultValue: "\(abiModuleName).\(CAbi.eventRegistrationTokenName)()",
                    abiKind: .inert)

            case "HResult":
                return TypeProjection(
                    swiftType: .chain("COM", "HResult"),
                    abiType: .chain(abiModuleName, CAbi.hresultName),
                    projectionType: .chain("COM", "HResultProjection"),
                    abiDefaultValue: "S_OK",
                    abiKind: .inert)

            default:
                return nil
        }
    }
}