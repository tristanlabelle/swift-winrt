import CodeWriters
import DotNetMetadata
import ProjectionGenerator
import WindowsMetadata

internal func writeStructDefinition(_ structDefinition: StructDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeStruct(
            documentation: projection.getDocumentationComment(structDefinition),
            visibility: SwiftProjection.toVisibility(structDefinition.visibility),
            name: try projection.toTypeName(structDefinition),
            typeParams: structDefinition.genericParams.map { $0.name },
            protocolConformances: [ .identifier("Hashable"), .identifier("Codable") ]) { writer throws in
        try writeStructFields(structDefinition, projection: projection, to: writer)
        try writeDefaultInitializer(structDefinition, projection: projection, to: writer)
        try writeFieldwiseInitializer(structDefinition, projection: projection, to: writer)
    }

    if structDefinition.fullName == "Windows.Foundation.DateTime" {
        try writeDateTimeExtensions(typeName: try projection.toTypeName(structDefinition), to: writer)
    }
    else if structDefinition.fullName == "Windows.Foundation.TimeSpan" {
        try writeTimeSpanExtensions(typeName: try projection.toTypeName(structDefinition), to: writer)
    }
}

fileprivate func writeStructFields(_ structDefinition: StructDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    for field in structDefinition.fields {
        assert(field.isInstance && !field.isInitOnly && field.isPublic)

        try writer.writeStoredProperty(
            documentation: projection.getDocumentationComment(field),
            visibility: .public, declarator: .var, name: SwiftProjection.toMemberName(field),
            type: projection.toType(field.type))
    }
}

fileprivate func writeDefaultInitializer(_ structDefinition: StructDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
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
            let name = SwiftProjection.toMemberName(field)
            let initializer = getInitializer(type: try field.type)
            writer.writeStatement("self.\(name) = \(initializer)")
        }
    }
}

fileprivate func writeFieldwiseInitializer(_ structDefinition: StructDefinition, projection: SwiftProjection, to writer: SwiftTypeDefinitionWriter) throws {
    let params = try structDefinition.fields
        .filter { $0.visibility == .public && $0.isInstance }
        .map { SwiftParam(name: SwiftProjection.toMemberName($0), type: try projection.toType($0.type)) }
    guard !params.isEmpty else { return }

    writer.writeInit(visibility: .public, params: params) {
        for param in params {
            $0.output.write("self.\(param.name) = \(param.name)", endLine: true)
        }
    }
}

fileprivate func writeDateTimeExtensions(typeName: String, to writer: SwiftSourceFileWriter) throws {
    writer.writeImport(module: "Foundation", struct: "Date")

    writer.writeExtension(name: typeName) { writer in
        // public init(foundationDate: Date)
        writer.writeInit(visibility: .public,
                params: [.init(name: "foundationDate", type: .chain("Foundation", "Date"))]) { writer in
            // TimeInterval has limited precision to work with (it is a Double), so explicitly work at millisecond precision
            writer.writeStatement("self.init(universalTime: (Int64(foundationDate.timeIntervalSince1970 * 1000) + 11_644_473_600_000) * 10_000)")
        }

        // public var foundationDate: Date
        writer.writeComputedProperty(visibility: .public, name: "foundationDate", type: .chain("Foundation", "Date"),
            get: { writer in
                // TimeInterval has limited precision to work with (it is a Double), so explicitly work at millisecond precision
                writer.writeStatement("Date(timeIntervalSince1970: Double(universalTime / 10_000) / 1000 - 11_644_473_600)")
            },
            set: { writer in
                writer.writeStatement("self = Self(foundationDate: newValue)")
            })
    }
}

fileprivate func writeTimeSpanExtensions(typeName: String, to writer: SwiftSourceFileWriter) throws {
    writer.writeImport(module: "Foundation", struct: "TimeInterval")

    writer.writeExtension(name: typeName) { writer in
        // public init(timeInterval: TimeInterval)
        writer.writeInit(visibility: .public,
                params: [.init(name: "timeInterval", type: .chain("Foundation", "TimeInterval"))]) { writer in
            writer.writeStatement("self.init(duration: Int64(timeInterval * 10_000_000))")
        }

        // public var timeInterval: TimeInterval
        writer.writeComputedProperty(visibility: .public, name: "timeInterval", type: .chain("Foundation", "TimeInterval"),
            get: { writer in
                writer.writeStatement("Double(duration) / 10_000_000")
            },
            set: { writer in
                writer.writeStatement("self = Self(timeInterval: newValue)")
            })
    }
}