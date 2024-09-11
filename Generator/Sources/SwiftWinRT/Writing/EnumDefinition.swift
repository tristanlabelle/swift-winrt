import CodeWriters
import DotNetMetadata
import ProjectionModel

internal func writeEnumDefinition(_ enumDefinition: EnumDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    if SupportModules.WinRT.getBuiltInTypeKind(enumDefinition) != nil {
        // Defined in WindowsRuntime, merely reexport it here.
        let typeName = try projection.toTypeName(enumDefinition)
        writer.writeImport(exported: true, kind: .struct, module: SupportModules.WinRT.moduleName, symbolName: typeName)
        return
    }

    if try projection.isSwiftEnumEligible(enumDefinition) {
        try writeClosedEnumDefinition(enumDefinition, projection: projection, to: writer)
    }
    else {
        try writeOpenEnumDefinition(enumDefinition, projection: projection, to: writer)
    }
}

fileprivate func writeOpenEnumDefinition(_ enumDefinition: EnumDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    // Enums are syntactic sugar for integers in .NET,
    // so we cannot guarantee that the enumerants are exhaustive,
    // therefore we cannot project them to Swift enums
    // since they would be unable to represent unknown values.
    try writer.writeStruct(
            documentation: projection.getDocumentationComment(enumDefinition),
            visibility: SwiftProjection.toVisibility(enumDefinition.visibility),
            name: try projection.toTypeName(enumDefinition),
            protocolConformances: [
                .identifier(name: enumDefinition.isFlags ? "OptionSet" : "RawRepresentable"),
                .identifier("Codable"),
                .identifier("Hashable"),
                .identifier("Sendable") ]) { writer throws in

        let rawValueType = try projection.toType(enumDefinition.underlyingType.bindNode())
        writer.writeStoredProperty(visibility: .public, declarator: .var, name: "rawValue", type: rawValueType)
        writer.writeInit(visibility: .public,
            params: [ .init(name: "rawValue", type: rawValueType, defaultValue: "0") ]) {
            $0.output.write("self.rawValue = rawValue")
        }

        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            let value = SwiftProjection.toConstant(try field.literalValue!)
            // Avoid "warning: static property '<foo>' produces an empty option set"
            let initializer = value == "0" ? "Self()" : "Self(rawValue: \(value))"
            try writer.writeStoredProperty(
                documentation: projection.getDocumentationComment(field),
                visibility: .public, static: true, declarator: .let,
                name: SwiftProjection.toMemberName(field),
                initialValue: initializer)
        }
    }
}

fileprivate func writeClosedEnumDefinition(_ enumDefinition: EnumDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeEnum(
            documentation: projection.getDocumentationComment(enumDefinition),
            visibility: SwiftProjection.toVisibility(enumDefinition.visibility),
            name: try projection.toTypeName(enumDefinition),
            rawValueType: try projection.toType(enumDefinition.underlyingType.bindNode()),
            protocolConformances: [
                .identifier("Codable"),
                .identifier("Hashable"),
                .identifier("Sendable") ]) { writer throws in
        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            try writer.writeEnumCase(
                documentation: projection.getDocumentationComment(field),
                name: SwiftProjection.toMemberName(field),
                rawValue: SwiftProjection.toConstant(try field.literalValue!))
        }
    }
}