import CodeWriters
import DotNetMetadata
import WindowsMetadata

extension SwiftProjectionWriter {
    internal func writeStructDefinitionAndProjection(_ structDefinition: StructDefinition, to writer: SwiftSourceFileWriter) throws {
        try writer.writeStruct(
                documentation: projection.getDocumentationComment(structDefinition),
                visibility: SwiftProjection.toVisibility(structDefinition.visibility),
                name: try projection.toTypeName(structDefinition),
                typeParams: structDefinition.genericParams.map { $0.name },
                protocolConformances: [ .identifier("Hashable"), .identifier("Codable") ]) { writer throws in
            try writeStructFields(structDefinition, to: writer)
            try writeDefaultInitializer(structDefinition, to: writer)
            try writeFieldwiseInitializer(structDefinition, to: writer)
        }

        if structDefinition.fullName == "Windows.Foundation.DateTime" {
            try writeDateTimeExtensions(typeName: try projection.toTypeName(structDefinition), to: writer)
        }
        else if structDefinition.fullName == "Windows.Foundation.TimeSpan" {
            try writeTimeSpanExtensions(typeName: try projection.toTypeName(structDefinition), to: writer)
        }

        // Write ABIProjection conformance as an extension
        try writeStructProjection(structDefinition, to: writer)
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

        try writer.writeInit(visibility: .public, params: []) { writer in
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
            .map { SwiftParam(name: projection.toMemberName($0), type: try projection.toType($0.type)) }
        guard !params.isEmpty else { return }

        writer.writeInit(visibility: .public, params: params) {
            for param in params {
                $0.output.write("self.\(param.name) = \(param.name)", endLine: true)
            }
        }
    }

    fileprivate func writeStructProjection(_ structDefinition: StructDefinition, to writer: SwiftSourceFileWriter) throws {
        let abiType = SwiftType.chain(projection.abiModuleName, try CAbi.mangleName(type: structDefinition.bindType()))

        // TODO: Support strings and IReference<T> field types (non-inert)
        // extension <struct>: ABIInertProjection
        try writer.writeExtension(
                name: try projection.toTypeName(structDefinition),
                protocolConformances: [SwiftType.chain("COM", "ABIInertProjection")]) { writer in

            // public typealias SwiftValue = Self
            writer.writeTypeAlias(visibility: .public, name: "SwiftValue", target: .`self`)

            // public typealias ABIValue = <abi-type>
            writer.writeTypeAlias(visibility: .public, name: "ABIValue", target: abiType)

            // public static var abiDefaultValue: ABIValue { .init() }
            writer.writeComputedProperty(
                    visibility: .public, static: true, name: "abiDefaultValue", type: abiType) { writer in
                writer.writeStatement(".init()")
            }

            // public static func toSwift(_ value: ABIValue) -> SwiftValue { .init(field: value.Field, ...) }
            try writer.writeFunc(
                    visibility: .public, static: true, name: "toSwift",
                    params: [.init(label: "_", name: "value", type: abiType)], 
                    returnType: .`self`) { writer in
                var expression = ".init("
                for (index, field) in structDefinition.fields.enumerated() {
                    guard field.isInstance else { continue }
                    if index > 0 { expression += ", " }

                    SwiftIdentifier.write(projection.toMemberName(field), to: &expression)
                    expression += ": "

                    let typeProjection = try projection.getTypeProjection(field.type)
                    if typeProjection.kind == .identity {
                        expression += "value."
                        SwiftIdentifier.write(field.name, to: &expression)
                    }
                    else {
                        typeProjection.projectionType.write(to: &expression)
                        expression += ".toSwift("
                        expression += "value."
                        SwiftIdentifier.write(field.name, to: &expression)
                        expression += ")"
                    }
                }
                expression += ")"
                writer.writeStatement(expression)
            }

            // public static func toABI(_ value: SwiftValue) -> ABIValue { .init(Field: value.field, ...) }
            try writer.writeFunc(
                    visibility: .public, static: true, name: "toABI",
                    params: [.init(label: "_", name: "value", type: .`self`)],
                    returnType: abiType) { writer in
                var expression = ".init("
                for (index, field) in structDefinition.fields.enumerated() {
                    guard field.isInstance else { continue }
                    if index > 0 { expression += ", " }

                    SwiftIdentifier.write(field.name, to: &expression)
                    expression += ": "

                    let typeProjection = try projection.getTypeProjection(field.type)
                    if typeProjection.kind == .identity {
                        expression += "value."
                        SwiftIdentifier.write(projection.toMemberName(field), to: &expression)
                    }
                    else {
                        if typeProjection.kind != .inert { expression.append("try! ") }
                        typeProjection.projectionType.write(to: &expression)
                        expression += ".toABI("
                        expression += "value."
                        SwiftIdentifier.write(projection.toMemberName(field), to: &expression)
                        expression += ")"
                    }
                }
                expression += ")"
                writer.writeStatement(expression)
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
}