import CodeWriters
import DotNetMetadata

public struct SwiftNamespaceModuleFileWriter {
    private let sourceFileWriter: SwiftSourceFileWriter
    private let module: SwiftProjection.Module
    private var projection: SwiftProjection { module.projection }

    public init(path: String, module: SwiftProjection.Module) {
        self.sourceFileWriter = SwiftSourceFileWriter(output: FileTextOutputStream(path: path))
        self.module = module

        writeGeneratedCodePreamble(to: sourceFileWriter)
        sourceFileWriter.writeImport(module: module.name)
    }

    public func writeAliases(_ typeDefinition: TypeDefinition) throws {
        if let interface = typeDefinition as? InterfaceDefinition {
            try sourceFileWriter.writeProtocol(
                visibility: SwiftProjection.toVisibility(interface.visibility),
                name: projection.toProtocolName(interface, namespaced: false),
                typeParams: interface.genericParams.map { $0.name },
                bases: [projection.toBaseProtocol(interface)]) { _ in }
        }

        try sourceFileWriter.writeTypeAlias(
            visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
            name: projection.toTypeName(typeDefinition, namespaced: false),
            typeParams: typeDefinition.genericParams.map { $0.name },
            target: SwiftType.identifier(
                name: projection.toTypeName(typeDefinition),
                genericArgs: typeDefinition.genericParams.map { SwiftType.identifier(name: $0.name) }))

        if typeDefinition is InterfaceDefinition || typeDefinition is DelegateDefinition {
            try sourceFileWriter.writeTypeAlias(
                visibility: SwiftProjection.toVisibility(typeDefinition.visibility),
                name: projection.toProjectionTypeName(typeDefinition, namespaced: false),
                target: SwiftType.identifier(
                    name: projection.toProjectionTypeName(typeDefinition)))
        }
    }
}