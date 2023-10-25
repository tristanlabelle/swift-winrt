import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeStruct(_ structDefinition: StructDefinition) throws {
        try sourceFileWriter.writeStruct(
            visibility: SwiftProjection.toVisibility(structDefinition.visibility),
            name: try projection.toTypeName(structDefinition),
            typeParameters: structDefinition.genericParams.map { $0.name },
            protocolConformances: [ .identifier("Hashable"), .identifier("Codable") ]) { writer throws in

            try writeStructFields(structDefinition, to: writer)
            // TODO: Default initialize fields in default initializer only
            writer.writeInit(visibility: .public, parameters: []) { _ in } // Default initializer
            try writeFieldwiseInitializer(of: structDefinition, to: writer)
        }
    }

    fileprivate func writeStructFields(_ structDefinition: StructDefinition, to writer: SwiftRecordBodyWriter) throws {
        // FIXME: Rather switch on TypeDefinition to properly handle enum cases
        func getDefaultValue(_ type: SwiftType) -> String? {
            if case .optional = type { return "nil" }
            guard case .chain(let chain) = type,
                chain.components.count == 1 else { return nil }
            switch chain.components[0].identifier.name {
                case "Bool": return "false"
                case "Int", "UInt", "Int8", "UInt8", "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64": return "0"
                case "Float", "Double": return "0.0"
                case "String": return "\"\""
                default: return ".init()"
            }
        }

        for field in structDefinition.fields {
            assert(field.isInstance && !field.isInitOnly && field.isPublic)

            let type = try projection.toType(field.type)
            writer.writeStoredProperty(
                visibility: SwiftProjection.toVisibility(field.visibility),
                declarator: .var, name: projection.toMemberName(field), type: type,
                initialValue: getDefaultValue(type))
        }
    }

    fileprivate func writeFieldwiseInitializer(of structDefinition: StructDefinition, to writer: SwiftRecordBodyWriter) throws {
        let params = try structDefinition.fields
            .filter { $0.visibility == .public && $0.isInstance }
            .map { SwiftParameter(name: projection.toMemberName($0), type: try projection.toType($0.type)) }
        guard !params.isEmpty else { return }

        writer.writeInit(visibility: .public, parameters: params) {
            for param in params {
                $0.output.write("self.\(param.name) = \(param.name)", endLine: true)
            }
        }
    }

    internal func writeStructProjection(_ structDefinition: StructDefinition) throws {
        let abiType = SwiftType.chain(projection.abiModuleName, try CAbi.mangleName(type: structDefinition.bindType()))

        sourceFileWriter.writeExtension(
                name: try projection.toTypeName(structDefinition),
                protocolConformances: [SwiftType.chain("COM", "ABIInertProjection")]) { writer in

            writer.writeTypeAlias(visibility: .public, name: "SwiftValue", target: .`self`)
            writer.writeTypeAlias(visibility: .public, name: "ABIValue", target: abiType)

            writer.writeComputedProperty(
                    visibility: .public, static: true, name: "abiDefaultValue", type: abiType) { writer in
                writer.writeStatement(".init()")
            }
            writer.writeFunc(
                    visibility: .public, static: true, name: "toSwift",
                    parameters: [.init(label: "_", name: "value", type: abiType)], 
                    returnType: .`self`) { writer in
                writer.writeNotImplemented()
            }
            writer.writeFunc(
                    visibility: .public, static: true, name: "toABI",
                    parameters: [.init(label: "_", name: "value", type: .`self`)],
                    returnType: abiType) { writer in
                writer.writeNotImplemented()
            }
        }
    }
}