import CodeWriters
import DotNetMetadata
import struct Foundation.UUID

extension SwiftAssemblyModuleFileWriter {
    func writeProjection(_ typeDefinition: TypeDefinition) throws {
        if let interfaceDefinition = typeDefinition as? InterfaceDefinition {
            // Generic interfaces have no projection, only their instantiations do
            guard interfaceDefinition.genericArity == 0 else { return }
            try writeInterfaceProjection(interfaceDefinition)
        }
        else if let enumDefinition = typeDefinition as? EnumDefinition {
            try writeEnumProjection(enumDefinition)
        }
    }

    private func writeInterfaceProjection(_ interfaceDefinition: InterfaceDefinition) throws {
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

            try writeWinRTProjectionConformance(interfaceDefinition, to: writer)
            try writeInterfaceMembersProjection(interfaceDefinition, to: writer)
        }
    }

    private func writeWinRTProjectionConformance(_ interfaceDefinition: InterfaceDefinition, to writer: SwiftRecordBodyWriter) throws {
        writer.writeTypeAlias(visibility: .public, name: "SwiftValue",
            target: try projection.toType(interfaceDefinition.bindNode(), referenceNullability: .none))
        writer.writeTypeAlias(visibility: .public, name: "CStruct",
            target: projection.toAbiType(interfaceDefinition.bind(), referenceNullability: .none))
        writer.writeTypeAlias(visibility: .public, name: "CVTableStruct",
            target: projection.toAbiVTableType(interfaceDefinition.bind(), referenceNullability: .none))

        writer.writeStoredProperty(visibility: .public, static: true, let: true, name: "iid",
            initializer: try Self.toIIDInitializer(GuidAttribute.get(from: interfaceDefinition)))
        writer.writeStoredProperty(visibility: .public, static: true, let: true, name: "runtimeClassName",
            initializer: "\"\(interfaceDefinition.fullName)\"")
    }

    private static func toIIDInitializer(_ guidAttribute: GuidAttribute) throws -> String {
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

        let arguments = [
            toPrefixedPaddedHex(guidAttribute.a),
            toPrefixedPaddedHex(guidAttribute.b),
            toPrefixedPaddedHex(guidAttribute.c),
            toPrefixedPaddedHex((UInt16(guidAttribute.d) << 8) | UInt16(guidAttribute.e)),
            toPrefixedPaddedHex(
                (UInt64(guidAttribute.f) << 40) | (UInt64(guidAttribute.g) << 32)
                | (UInt64(guidAttribute.h) << 24) | (UInt64(guidAttribute.i) << 16)
                | (UInt64(guidAttribute.j) << 8) | (UInt64(guidAttribute.k) << 0),
                minimumLength: 12)
        ]
        return "IID(\(arguments.joined(separator: ", ")))"
    }

    private func writeInterfaceMembersProjection(_ interfaceDefinition: InterfaceDefinition, to writer: SwiftRecordBodyWriter) throws {
        for property in interfaceDefinition.properties {
            if let getter = try property.getter, getter.isPublic {
                try writer.writeComputedProperty(
                    visibility: .public,
                    name: projection.toMemberName(property),
                    type: projection.toReturnType(property.type),
                    throws: true) { writer throws in

                    writer.writeNotImplemented()
                }
            }

            if let setter = try property.setter, setter.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    name: projection.toMemberName(property),
                    parameters: [SwiftParameter(
                        label: "_", name: "newValue",
                        type: projection.toType(property.type, referenceNullability: .explicit))],
                    throws: true) { writer throws in

                    writer.writeNotImplemented()
                }
            }
        }

        for method in interfaceDefinition.methods {
            if method.isPublic {
                try writer.writeFunc(
                    visibility: .public,
                    name: projection.toMemberName(method),
                    parameters: method.params.map(projection.toParameter),
                    throws: true,
                    returnType: projection.toReturnTypeUnlessVoid(method.returnType)) { writer throws in

                    writer.writeNotImplemented()
                }
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
}