public struct SwiftSourceFileWriter: SwiftDeclarationWriter {
    public let output: IndentedTextOutputStream

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = IndentedTextOutputStream(inner: output, indent: indent)
    }

    public func writeImport(module: String) {
        output.beginLine(grouping: .withName("import"))
        output.write("import ")
        output.write(module, endLine: true)
    }

    public func writeImport(module: String, struct: String) {
        output.beginLine(grouping: .withName("import"))
        output.write("import struct ")
        output.write(module)
        output.write(".")
        output.write(`struct`, endLine: true)
    }

    public func writeExtension(
        type: SwiftType,
        protocolConformances: [SwiftType] = [],
        whereClauses: [String] = [],
        members: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
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