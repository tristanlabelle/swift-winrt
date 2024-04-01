import CodeWriters
import DotNetMetadata
import ProjectionModel

internal func writeNamespaceAlias(_ typeDefinition: TypeDefinition, projection: SwiftProjection, to writer: SwiftSourceFileWriter) throws {
    try writer.writeTypeAlias(
        visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
        name: projection.toTypeName(typeDefinition, namespaced: false),
        typeParams: typeDefinition.genericParams.map { $0.name },
        target: SwiftType.identifier(
            name: projection.toTypeName(typeDefinition),
            genericArgs: typeDefinition.genericParams.map { SwiftType.identifier(name: $0.name) }))

    if let interface = typeDefinition as? InterfaceDefinition {
        try writer.writeProtocol(
            visibility: SwiftProjection.toVisibility(interface.visibility),
            name: projection.toProtocolName(interface, namespaced: false),
            typeParams: interface.genericParams.map { $0.name },
            bases: [projection.toBaseProtocol(interface)]) { _ in }
    }

    if typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition {
        try writer.writeTypeAlias(
            visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
            name: projection.toProjectionTypeName(typeDefinition, namespaced: false),
            target: SwiftType.identifier(
                name: projection.toProjectionTypeName(typeDefinition)))
    }
}