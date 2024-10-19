public struct SwiftSourceFileWriter: SwiftDeclarationWriter {
    public let output: LineBasedTextOutputStream

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = LineBasedTextOutputStream(inner: output, defaultBlockLinePrefix: indent)
    }

    public func writeImport(exported: Bool = false, module: String) {
        output.beginLine(group: .named("import"))
        if exported { output.write("@_exported ") }
        output.write("import ")
        output.write(module, endLine: true)
    }

    public func writeImport(exported: Bool = false, kind: SwiftImportKind, module: String, symbolName: String) {
        output.beginLine(group: .named("import"))
        if exported { output.write("@_exported ") }
        output.write("import ")
        output.write(String(describing: kind))
        output.write(" ")
        output.write(module)
        output.write(".")
        output.write(symbolName, endLine: true)
    }

    public func writeExtension(
        type: SwiftType,
        protocolConformances: [SwiftType] = [],
        whereClauses: [String] = [],
        members: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(group: .none)
        output.write("extension ")
        type.write(to: &output)
        writeInheritanceClause(protocolConformances)
        if !whereClauses.isEmpty {
            output.write(" where ")
            output.write(whereClauses.joined(separator: ", "))
        }
        try output.writeBracedIndentedBlock() {
            try members(.init(output: output))
        }
    }
}