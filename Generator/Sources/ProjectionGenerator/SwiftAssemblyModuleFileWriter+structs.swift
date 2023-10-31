import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeStruct(_ structDefinition: StructDefinition) throws {
        try sourceFileWriter.writeStruct(
            documentation: projection.getDocumentationComment(structDefinition),
            visibility: SwiftProjection.toVisibility(structDefinition.visibility),
            name: try projection.toTypeName(structDefinition),
            typeParameters: structDefinition.genericParams.map { $0.name },
            protocolConformances: [ .identifier("Hashable"), .identifier("Codable") ]) { writer throws in

            try writeStructFields(structDefinition, to: writer)
            try writeDefaultInitializer(structDefinition, to: writer)
            try writeFieldwiseInitializer(structDefinition, to: writer)
        }
    }

    fileprivate func writeStructFields(_ structDefinition: StructDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        for field in structDefinition.fields {
            assert(field.isInstance && !field.isInitOnly && field.isPublic)

            try writer.writeStoredProperty(
                documentation: projection.getDocumentationComment(field),
                visibility: .public, declarator: .var, name: projection.toMemberName(field),
                type: projection.toType(field.type))
        }
    }

    fileprivate func writeDefaultInitializer(_ structDefinition: StructDefinition, to writer: SwiftTypeDefinitionWriter) throws {
        func getInitializer(type: TypeNode) -> String {
            switch type {
                case .array(_): return "[]"
                case .pointer(_): return "nil"
                case .genericParam(_): fatalError()
                case .bound(let type):
                    if type.definition.namespace == "System" {
                        switch type.definition.name {
                            case "Boolean": return "false"
                            case "SByte", "Byte", "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64": return "0"
                            case "Single", "Double": return "0"
                            case "Char": return ".init()"
                            case "String": return "\"\""
                            default: fatalError()
                        }
                    }

                    return type.definition.isValueType ? ".init()" : "nil"
            }
        }

        try writer.writeInit(visibility: .public, parameters: []) { writer in
            for field in structDefinition.fields {
                let name = projection.toMemberName(field)
                let initializer = getInitializer(type: try field.type)
                writer.writeStatement("self.\(name) = \(initializer)")
            }
        }
    }

    fileprivate func writeFieldwiseInitializer(_ structDefinition: StructDefinition, to writer: SwiftTypeDefinitionWriter) throws {
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