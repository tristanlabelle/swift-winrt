import CodeWriters
import DotNetMetadata
import ProjectionModel

internal func writeTypeDefinition(
        _ typeDefinition: TypeDefinition,
        projection: Projection,
        swiftBug72724: Bool?,
        to writer: SwiftSourceFileWriter) throws {
    switch typeDefinition {
        case let structDefinition as StructDefinition:
            try writeStructDefinition(structDefinition, projection: projection, to: writer)
        case let enumDefinition as EnumDefinition:
            try writeEnumDefinition(enumDefinition, projection: projection, to: writer)
        case let interfaceDefinition as InterfaceDefinition:
            try writeInterfaceDefinition(interfaceDefinition, projection: projection,
                swiftBug72724: swiftBug72724, to: writer)
        case let delegateDefinition as DelegateDefinition:
            try writeDelegateDefinition(delegateDefinition, projection: projection, to: writer)
        case let classDefinition as ClassDefinition:
            try writeClassDefinition(classDefinition, projection: projection, to: writer)
        default:
            fatalError()
    }
}

fileprivate func writeDelegateDefinition(_ delegateDefinition: DelegateDefinition, projection: Projection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeTypeAlias(
        documentation: projection.getDocumentationComment(delegateDefinition),
        visibility: Projection.toVisibility(delegateDefinition.visibility),
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
