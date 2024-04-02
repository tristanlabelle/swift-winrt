import CodeWriters
import ProjectionModel

internal func writeGeneratedCodePreamble(to writer: SwiftSourceFileWriter) {
    writer.writeCommentLine("Generated by swift-winrt")
    writer.writeCommentLine("swiftlint:disable all", groupWithNext: false)
}

internal func writeModulePreamble(_ module: SwiftProjection.Module, importABI: Bool = true, to writer: SwiftSourceFileWriter) {
    writer.writeImport(module: SupportModules.WinRT.moduleName)

    if importABI {
        writer.writeImport(module: module.projection.abiModuleName)
    }

    for referencedModule in module.references {
        guard !referencedModule.isEmpty else { continue }
        writer.writeImport(module: referencedModule.name)
    }
}