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

                return try getSwiftTypeInfo(type).valueType
            case let .genericParam(param):
                return .identifier(param.name)
            case let .array(of: element):
                return .array(element: try toType(element))
            default:
                fatalError("Not implemented: Swift representation of values of type \(type)")
        }
    }

    public func toReturnType(_ type: TypeNode) throws -> SwiftType {
        let swiftType = try toType(type)
        if case .optional(let wrapped, implicitUnwrap: _) = swiftType {
            return referenceReturnNullability.applyTo(type: wrapped)
        }
        else {
            return swiftType
        }
    }

    private func getSwiftTypeInfo(_ type: BoundType) throws -> (name: String, objectType: SwiftType, valueType: SwiftType) {
        let swiftName = try toTypeName(type.definition)
        let swiftGenericArgs = try type.genericArgs.map { try toType($0) }
        let swiftObjectType = SwiftType.identifier(name: swiftName, genericArgs: swiftGenericArgs)
        let swiftValueType = type.definition.isValueType ? swiftObjectType : .optional(wrapped: swiftObjectType)
        return (swiftName, swiftObjectType, swiftValueType)
    }

    internal func getTypeProjection(_ type: TypeNode) throws -> TypeProjection {
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
            abiType = .optional(wrapped: .identifier("UnsafeMutablePointer", genericArgs: [abiType]))
        }

        let (swiftTypeName, swiftObjectType, swiftValueType) = try getSwiftTypeInfo(type)

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
            case .char: return .numeric(swiftType: .uint(bits: 16))
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
                let systemType = WinRTSystemType(fromName: type.definition.name) {
            switch systemType {
                case .integer(.uint8),
                    .integer(.int16), .integer(.uint16),
                    .integer(.int32), .integer(.uint32),
                    .integer(.int64), .integer(.uint64),
                    .float(double: false), .float(double: true):

                    let swiftType = try toType(type.asNode)
                    return TypeProjection(
                        swiftType: .optional(wrapped: swiftType),
                        swiftDefaultValue: "0",
                        projectionType: .chain(
                            .init("WindowsRuntime"),
                            .init("IReferenceNumericProjection", genericArgs: [ swiftType ])),
                        kind: .allocating,
                        abiDefaultValue: "nil")

                default: return nil
            }
        }

        return nil
    }
}