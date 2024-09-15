import CodeWriters
import DotNetMetadata
import ProjectionModel
import WindowsMetadata

internal func writeStructDefinition(_ structDefinition: StructDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(structDefinition) != nil {
        // Defined in WindowsRuntime, merely reexport it here.
        let typeName = try projection.toTypeName(structDefinition)
        writer.writeImport(exported: true, kind: .struct, module: SupportModules.WinRT.moduleName, symbolName: typeName)
    } else {
        let protocolConformances: [SwiftType] = [
            .identifier("Codable"),
            .identifier("Hashable"),
            .identifier("Sendable")
        ]
        try writer.writeStruct(
                documentation: projection.getDocumentationComment(structDefinition),
                visibility: Projection.toVisibility(structDefinition.visibility),
                name: try projection.toTypeName(structDefinition),
                typeParams: structDefinition.genericParams.map { $0.name },
                protocolConformances: protocolConformances) { writer throws in
            try writeStructFields(structDefinition, projection: projection, to: writer)
            try writeDefaultInitializer(structDefinition, projection: projection, to: writer)
            try writeFieldwiseInitializer(structDefinition, projection: projection, to: writer)
        }
    }
}

fileprivate func writeStructFields(_ structDefinition: StructDefinition, projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    for field in structDefinition.fields {
        assert(field.isInstance && !field.isInitOnly && field.isPublic)

        try writer.writeStoredProperty(
            documentation: projection.getDocumentationComment(field),
            visibility: .public, declarator: .var, name: Projection.toMemberName(field),
            type: projection.toType(field.type))
    }
}

fileprivate func writeDefaultInitializer(_ structDefinition: StructDefinition, projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
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

    try writer.writeInit(visibility: .public, params: []) { writer in
        for field in structDefinition.fields {
            let name = Projection.toMemberName(field)
            let initializer = getInitializer(type: try field.type)
            writer.writeStatement("self.\(name) = \(initializer)")
        }
    }
}

fileprivate func writeFieldwiseInitializer(_ structDefinition: StructDefinition, projection: Projection, to writer: SwiftTypeDefinitionWriter) throws {
    let params = try structDefinition.fields
        .filter { $0.visibility == .public && $0.isInstance }
        .map { SwiftParam(name: Projection.toMemberName($0), type: try projection.toType($0.type)) }
    guard !params.isEmpty else { return }

    writer.writeInit(visibility: .public, params: params) {
        for param in params {
            $0.output.write("self.\(param.name) = \(param.name)", endLine: true)
        }
    }
}
