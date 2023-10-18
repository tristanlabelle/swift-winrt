import CodeWriters
import Collections
import DotNetMetadata
import WindowsMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    func writeProjection(_ type: BoundType) throws {
        // TODO: Support generic interfaces/delegates

        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            // Generic interfaces have no projection, only their instantiations do
            guard interfaceDefinition.genericArity == 0 else { return }
            try writeInterfaceProjection(interfaceDefinition, genericArgs: type.genericArgs)
        }
        else if let classDefinition = type.definition as? ClassDefinition {
            try writeClassProjection(classDefinition)
        }
        else if let enumDefinition = type.definition as? EnumDefinition {
            try writeEnumProjection(enumDefinition)
        }
    }

    private func writeInterfaceProjection(_ interfaceDefinition: InterfaceDefinition, genericArgs: [TypeNode] = []) throws {
        let interface = interfaceDefinition.bind(genericArgs: genericArgs)
        let projectionTypeName = try projection.toProjectionTypeName(interfaceDefinition)
        try sourceFileWriter.writeClass(
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            final: true,
            name: projectionTypeName,
            base: .identifier(
                name: "WinRTProjectionBase",
                genericArgs: [.identifier(name: projectionTypeName)]),
            protocolConformances: [
                .identifier(name: "WinRTProjection"),
                .identifier(name: try projection.toProtocolName(interfaceDefinition))
            ]) { writer throws in

            try writeGenericTypeAliases(interfaces: [interface], to: writer)
            try writeWinRTProjectionConformance(type: interface, interface: interface, to: writer)
            try writeInterfaceMembersProjection(interface, to: writer)
        }
    }

    private func writeClassProjection(_ classDefinition: ClassDefinition) throws {
        let typeName = try projection.toTypeName(classDefinition)
        if let defaultInterface = try FoundationAttributes.getDefaultInterface(classDefinition) {
            try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                final: true,
                name: typeName,
                base: .identifier(
                    name: "WinRTProjectionBase",
                    genericArgs: [.identifier(name: typeName)]),
                protocolConformances: [.identifier(name: "WinRTProjection")]) { writer throws in

                try writeGenericTypeAliases(interfaces: classDefinition.baseInterfaces.map { try $0.interface }, to: writer)
                try writeWinRTProjectionConformance(type: classDefinition.bind(), interface: defaultInterface, to: writer)
                try writeInterfaceMembersProjection(defaultInterface, to: writer)
            }
        }
        else {
            // Static class
            try sourceFileWriter.writeClass(
                visibility: SwiftProjection.toVisibility(classDefinition.visibility),
                final: true,
                name: typeName) { writer throws in

                writer.writeInit(visibility: .private) { writer in }
            }
        }
    }

    private func writeEnumProjection(_ enumDefinition: EnumDefinition) throws {
        sourceFileWriter.writeExtension(
            name: try projection.toTypeName(enumDefinition),
            protocolConformances: [SwiftType.identifierChain("WindowsRuntime", "EnumProjection")]) { writer in

            writer.writeTypeAlias(visibility: .public, name: "CEnum",
                target: projection.toAbiType(enumDefinition.bind(), referenceNullability: .none))
        }
    }

    // For StringMap, will write typealiases for K = String and V = String
    private func writeGenericTypeAliases(interfaces: [BoundType], to writer: SwiftRecordBodyWriter) throws {
        // Gather type aliases by recursively visiting base types
        var typeAliases = OrderedDictionary<String, SwiftType>()
        func visit(interface: BoundType) throws {
            for genericParam in interface.definition.genericParams {
                // TODO: Don't assume that all instances of generic params of the same name are bound to the same type
                typeAliases[genericParam.name] = try projection.toType(interface.genericArgs[genericParam.index])
            }

            for baseInterface in interface.definition.baseInterfaces {
                let baseInterface = try baseInterface.interface
                try visit(interface: BoundType(baseInterface.definition,
                    genericArgs: baseInterface.genericArgs.map {
                        // Bind transitive generic arguments:
                        // For IVector<String>, IIterable<T> -> IIterable<String> 
                        if case .genericParam(let genericParam) = $0 {
                            return interface.genericArgs[genericParam.index]
                        }
                        else {
                            return $0
                        }
                    }))
            }
        }

        for interface in interfaces { try visit(interface: interface) }

        for (name, type) in typeAliases {
            writer.writeTypeAlias(visibility: .public, name: name, target: type)
        }
    }

    private func writeWinRTProjectionConformance(type: BoundType, interface: BoundType, to writer: SwiftRecordBodyWriter) throws {
        writer.writeTypeAlias(visibility: .public, name: "SwiftValue",
            target: try projection.toType(type.asNode, referenceNullability: .none))
        writer.writeTypeAlias(visibility: .public, name: "COMInterface",
            target: projection.toAbiType(interface, referenceNullability: .none))
        writer.writeTypeAlias(visibility: .public, name: "COMVirtualTable",
            target: projection.toAbiVTableType(interface, referenceNullability: .none))

        // TODO: Support generic interfaces
        writer.writeStoredProperty(visibility: .public, static: true, let: true, name: "iid",
            initializer: try Self.toIIDInitializer(FoundationAttributes.getGuid(interface.definition as! InterfaceDefinition)))
        writer.writeStoredProperty(visibility: .public, static: true, let: true, name: "runtimeClassName",
            initializer: "\"\(type.definition.fullName)\"")
    }

    private static func toIIDInitializer(_ uuid: UUID) throws -> String {
        func toPrefixedPaddedHex<Value: UnsignedInteger & FixedWidthInteger>(
            _ value: Value,
            minimumLength: Int = MemoryLayout<Value>.size * 2) -> String {

            var hex = String(value, radix: 16, uppercase: true)
            if hex.count < minimumLength {
                hex.insert(contentsOf: String(repeating: "0", count: minimumLength - hex.count), at: hex.startIndex)
            }
            hex.insert(contentsOf: "0x", at: hex.startIndex)
            return hex
        }

        let uuid = uuid.uuid
        let arguments = [
            toPrefixedPaddedHex((UInt32(uuid.0) << 24) | (UInt32(uuid.1) << 16) | (UInt32(uuid.2) << 8) | (UInt32(uuid.3) << 0)),
            toPrefixedPaddedHex((UInt32(uuid.4) << 8) | (UInt32(uuid.5) << 0)),
            toPrefixedPaddedHex((UInt32(uuid.6) << 8) | (UInt32(uuid.7) << 0)),
            toPrefixedPaddedHex((UInt32(uuid.8) << 8) | (UInt32(uuid.9) << 0)),
            toPrefixedPaddedHex(
                (UInt64(uuid.10) << 40) | (UInt64(uuid.11) << 32)
                | (UInt64(uuid.12) << 24) | (UInt64(uuid.13) << 16)
                | (UInt64(uuid.14) << 8) | (UInt64(uuid.15) << 0),
                minimumLength: 12)
        ]
        return "IID(\(arguments.joined(separator: ", ")))"
    }

    private func writeInterfaceMembersProjection(_ interface: BoundType, to writer: SwiftRecordBodyWriter) throws {
        // TODO: Support generic interfaces
        let interfaceDefinition = interface.definition
        for property in interfaceDefinition.properties {
            let typeProjection = try projection.getTypeProjection(property.type)

            if let getter = try property.getter, getter.isPublic {
                try writer.writeComputedProperty(
                    visibility: .public,
                    name: projection.toMemberName(property),
                    type: projection.toReturnType(property.type),
                    throws: true) { writer throws in

                    if let abiProjection = typeProjection.abi {
                        switch abiProjection {
                            case .identity:
                                writer.writeStatement("try _getter(_vtable.get_\(property.name))")
                            case .simple(abiType: _, let projectionType, inert: _):
                                writer.writeStatement("try _getter(_vtable.get_\(property.name), \(projectionType).self)")
                        }
                    }
                    else {
                        writer.writeNotImplemented()
                    }
                }
            }

            if let setter = try property.setter, setter.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    name: projection.toMemberName(property),
                    parameters: [SwiftParameter(
                        label: "_", name: "newValue",
                        type: projection.toType(property.type))],
                    throws: true) { writer throws in

                    if let abiProjection = typeProjection.abi {
                        switch abiProjection {
                            case .identity:
                                writer.writeStatement("try _setter(_vtable.get_\(property.name), newValue)")
                            case .simple(abiType: _, let projectionType, inert: _):
                                writer.writeStatement("try _getter(_vtable.get_\(property.name), newValue, \(projectionType).self)")
                        }
                    }
                    else {
                        writer.writeNotImplemented()
                    }
                }
            }
        }

        for method in interfaceDefinition.methods {
            guard method.isPublic, method.nameKind == .regular else { continue }

            try writer.writeFunc(
                visibility: .public,
                name: projection.toMemberName(method),
                parameters: method.params.map(projection.toParameter),
                throws: true,
                returnType: projection.toReturnTypeUnlessVoid(method.returnType)) { writer throws in

                var abiArgs = ["_pointer"]
                for param in try method.params {
                    guard let paramName = param.name else {
                        writer.writeNotImplemented()
                        return
                    }

                    let typeProjection = try projection.getTypeProjection(param.type)
                    guard let abiProjection = typeProjection.abi else {
                        writer.writeNotImplemented()
                        return
                    }

                    if case let .simple(abiType: _, projectionType: projectionType, inert: inert) = abiProjection {
                        writer.writeStatement("let \(paramName) = \(projectionType).toAbi(\(paramName))")
                        if !inert { writer.writeStatement("defer { \(paramName).release() }") }
                    }

                    abiArgs.append(paramName)
                }

                func writeCall() {
                    // TODO: Handle overload names
                    writer.writeStatement("try HResult.throwIfFailed(_vtable.\(method.name)(\(abiArgs.joined(separator: ", "))))")
                }

                guard try method.hasReturnValue else {
                    writeCall()
                    return
                }

                let returnTypeProjection = try projection.getTypeProjection(method.returnType)
                guard let returnAbiProjection = returnTypeProjection.abi else {
                    writer.writeNotImplemented()
                    return
                }

                switch returnAbiProjection {
                    case .identity(abiType: let abiType):
                        writer.writeStatement("var _result = \(abiType)()")
                        abiArgs.append("&_result")
                        writeCall()
                        writer.writeStatement("return _result")

                    case .simple(abiType: let abiType, let projectionType, inert: _):
                        writer.writeStatement("var _result = \(abiType)()")
                        abiArgs.append("&_result")
                        writeCall()
                        writer.writeStatement("return \(projectionType).toSwift(consuming: _result)")
                }
            }
        }
    }
}