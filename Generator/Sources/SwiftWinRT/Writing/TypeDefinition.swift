import CodeWriters
import DotNetMetadata
import ProjectionGenerator

internal func writeTypeDefinition(_ typeDefinition: TypeDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    switch typeDefinition {
        case let structDefinition as StructDefinition:
            try writeStructDefinition(structDefinition, projection: projection, to: writer)
        case let enumDefinition as EnumDefinition:
            try writeEnumDefinition(enumDefinition, projection: projection, to: writer)
        case let interfaceDefinition as InterfaceDefinition:
            try writeInterfaceDefinition(interfaceDefinition, projection: projection, to: writer)
        case let delegateDefinition as DelegateDefinition:
            try writeDelegateDefinition(delegateDefinition, projection: projection, to: writer)
        case let classDefinition as ClassDefinition:
            try writeClassDefinition(classDefinition, projection: projection, to: writer)
        default:
            fatalError()
    }
}

fileprivate func writeEnumDefinition(_ enumDefinition: EnumDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
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
                .identifier("Hashable"),
                .identifier("Codable") ]) { writer throws in

        let rawValueType = try projection.toType(enumDefinition.underlyingType.bindNode())
        writer.writeStoredProperty(visibility: .public, declarator: .var, name: "rawValue", type: rawValueType)
        writer.writeInit(visibility: .public,
            params: [ .init(name: "rawValue", type: rawValueType, defaultValue: "0") ]) {
            $0.output.write("self.rawValue = rawValue")
        }

        for field in enumDefinition.fields.filter({ $0.visibility == .public && $0.isStatic }) {
            let value = SwiftProjection.toConstant(try field.literalValue!)
            try writer.writeStoredProperty(
                documentation: projection.getDocumentationComment(field),
                visibility: .public, static: true, declarator: .let,
                name: SwiftProjection.toMemberName(field),
                initialValue: "Self(rawValue: \(value))")
        }
    }
}

fileprivate func writeDelegateDefinition(_ delegateDefinition: DelegateDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeTypeAlias(
        documentation: projection.getDocumentationComment(delegateDefinition),
        visibility: SwiftProjection.toVisibility(delegateDefinition.visibility),
        name: try projection.toTypeName(delegateDefinition),
        typeParams: delegateDefinition.genericParams.map { $0.name },
        target: .function(
            params: delegateDefinition.invokeMethod.params.map { try projection.toType($0.type) },
            throws: true,
            returnType: delegateDefinition.invokeMethod.hasReturnValue 
                ? projection.toReturnType(delegateDefinition.invokeMethod.returnType)
                : .void
        )
    )
}
