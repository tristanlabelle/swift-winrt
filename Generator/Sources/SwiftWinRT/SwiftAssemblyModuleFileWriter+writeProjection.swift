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
        let swiftTypeName = try projection.toTypeName(interfaceDefinition)
        let projectionName = swiftTypeName + "Projection"
        try sourceFileWriter.writeClass(
            visibility: SwiftProjection.toVisibility(interfaceDefinition.visibility),
            final: true,
            name: projectionName,
            base: .identifier(
                name: "WinRTProjectionBase",
                genericArgs: [.identifier(name: projectionName)]),
            protocolConformances: [
                .identifier(name: "WinRTProjection"),
                .identifier(name: try projection.toProtocolName(interfaceDefinition))
            ]) { writer in

            writer.writeTypeAlias(
                visibility: .public,
                name: "SwiftValue",
                target: .identifier(name: swiftTypeName))
            writer.writeTypeAlias(
                visibility: .public,
                name: "CStruct",
                target: projection.toAbiType(interfaceDefinition.bind()))
            writer.writeTypeAlias(
                visibility: .public,
                name: "CVTableStruct",
                target: projection.toAbiVTableType(interfaceDefinition.bind()))

            let guidAttribute = try GuidAttribute.get(from: interfaceDefinition)
            writer.writeStoredProperty(
                visibility: .public,
                static: true,
                let: true,
                name: "iid",
                initializer: try Self.toIIDInitializer(guidAttribute))
            writer.writeStoredProperty(
                visibility: .public,
                static: true,
                let: true,
                name: "runtimeClassName",
                initializer: "\"\(interfaceDefinition.fullName)\"")
        }
    }

    private static func toIIDInitializer(_ guidAttribute: GuidAttribute) throws -> String {
        let arguments = [
            String(format: "0x%08X", guidAttribute.a),
            String(format: "0x%04X", guidAttribute.b),
            String(format: "0x%04X", guidAttribute.c),
            String(format: "0x%04X", (UInt16(guidAttribute.d) << 8) | UInt16(guidAttribute.e)),
            String(format: "0x%012X",
                (UInt64(guidAttribute.f) << 40) | (UInt64(guidAttribute.g) << 32)
                | (UInt64(guidAttribute.h) << 40) | (UInt64(guidAttribute.i) << 32)
                | (UInt64(guidAttribute.j) << 40) | (UInt64(guidAttribute.k) << 32))
        ]
        return "IID(\(arguments.joined(separator: ", ")))"
    }

    private func writeEnumProjection(_ enumDefinition: EnumDefinition) throws {
        sourceFileWriter.writeExtension(
            name: try projection.toTypeName(enumDefinition),
            protocolConformances: [SwiftType.identifierChain("WindowsRuntime", "EnumProjection")]) { writer in

            writer.writeTypeAlias(
                visibility: .public,
                name: "CEnum",
                target: projection.toAbiType(enumDefinition.bind()))
        }
    }
}