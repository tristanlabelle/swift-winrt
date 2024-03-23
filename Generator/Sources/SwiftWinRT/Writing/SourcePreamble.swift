import CodeWriters
import ProjectionModel

internal func writeGeneratedCodePreamble(to writer: SwiftSourceFileWriter) {
    writer.writeCommentLine("Generated by swift-winrt")
    writer.writeCommentLine("swiftlint:disable all", groupWithNext: false)
}

internal func writeModulePreamble(_ module: SwiftProjection.Module, to writer: SwiftSourceFileWriter) {
    writer.writeImport(module: module.projection.abiModuleName)
    writer.writeImport(module: SupportModules.WinRT.moduleName)

    for referencedModule in module.references {
        guard !referencedModule.isEmpty else { continue }
        writer.writeImport(module: referencedModule.name)
    }

    writer.writeImport(module: "Foundation", struct: "UUID")
}