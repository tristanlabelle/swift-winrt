import CodeWriters
import DotNetMetadata

extension SwiftAssemblyModuleFileWriter {
    internal func writeEnum(_ enumDefinition: EnumDefinition) throws {
        // Enums are syntactic sugar for integers in .NET,
        // so we cannot guarantee that the enumerants are exhaustive,
        // therefore we cannot project them to Swift enums
        // since they would be unable to represent unknown values.
        try sourceFileWriter.writeStruct(
            documentation: projection.getDocumentationComment(enumDefinition),
            visibility: SwiftProjection.toVisibility(enumDefinition.visibility),
            name: try projection.toTypeName(enumDefinition),
            protocolConformances: [
                .identifier(name: enumDefinition.isFlags ? "OptionSet" : "RawRepresentable"),
                .identifier("Hashable"),
                .identifier("Codable") ]) { writer throws in

            let rawValueType = try projection.toType(enumDefinition.underlyingType.bindNode())
            writer.writeStoredProperty(visibility: .public, declarator: .var, name: "rawValue", type: rawValueType)
            writer.writeInit(visibility: .public,
                parameters: [ .init(name: "rawValue", type: rawValueType, defaultValue: "0") ]) {
                $0.output.write("self.rawValue = rawValue")
            }

            for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
                let value = SwiftProjection.toConstant(try field.literalValue!)
                try writer.writeStoredProperty(
                    documentation: projection.getDocumentationComment(field),
                    visibility: .public, static: true, declarator: .let,
                    name: projection.toMemberName(field),
                    initialValue: "Self(rawValue: \(value))")
            }
        }
    }

    internal func writeEnumProjection(_ enumDefinition: EnumDefinition) throws {
        try sourceFileWriter.writeExtension(
            name: projection.toTypeName(enumDefinition),
            protocolConformances: [SwiftType.chain("WindowsRuntime", "IntegerEnumProjection")]) { _ in }
    }
}