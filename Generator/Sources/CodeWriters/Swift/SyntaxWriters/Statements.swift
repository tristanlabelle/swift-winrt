public struct SwiftStatementWriter: SwiftSyntaxWriter {
    public let output: LineBasedTextOutputStream

    public func writeVariableDeclaration(
        declarator: SwiftVariableDeclarator, name: String, type: SwiftType? = nil, initializer: String? = nil) {

        var output = output
        output.write(declarator == .let ? "let " : "var ")
        SwiftIdentifier.write(name, to: &output)
        if let type {
            output.write(": ")
            type.write(to: &output)
        }
        if let initializer {
            output.write(" = ")
            output.write(initializer)
        }
        output.endLine()
    }

    public func writeReturnStatement(value: String? = nil) {
        output.write("return")
        if let value {
            output.write(" ")
            output.write(value)
        }
        output.endLine()
    }

    public func writeFatalError(_ message: String? = nil) {
        output.write("fatalError(")
        if let message {
            output.write("\"")
            output.write(message)
            output.write("\"")
        }
        output.write(")", endLine: true)
    }

    public func writeNotImplemented() {
        writeFatalError("Not implemented: \\(#function)")
    }

    public func writeBlankLine() {
        output.writeFullLine()
    }

    public func writeStatement(_ code: String) {
        let lines = code.split(separator: "\n")
        output.write(String(lines[0]), endLine: true)
        if lines.count == 1 { return }
        output.writeLineBlock {
            for line in lines.dropFirst() {
                output.write(String(line), endLine: true)
            }
        }
    }

    public func writeBracedBlock(_ header: String, _ body: (_ writer: SwiftStatementWriter) throws -> Void) rethrows {
        try output.writeBracedIndentedBlock(header) {
            try body(SwiftStatementWriter(output: output))
        }
    }

    public func writeIf(
            conditions: [String],
            then: (_ writer: SwiftStatementWriter) throws -> Void,
            else: ((_ writer: SwiftStatementWriter) throws -> Void)? = nil) rethrows {
        precondition(!conditions.isEmpty)
        output.write("if ")
        for (index, condition) in conditions.enumerated() {
            if index > 0 { output.write(", ") }
            output.write(condition)
        }
        output.write(" {", endLine: true)
        try output.writeLineBlock { try then(SwiftStatementWriter(output: output)) }
        output.endLine()
        output.write("}")
        if let `else` {
            output.write(" else {", endLine: true)
            try output.writeLineBlock { try `else`(SwiftStatementWriter(output: output)) }
            output.endLine()
            output.write("}")
        }
        output.endLine()
    }

    public func writeIf(
            _ condition: String,
            then: (_ writer: SwiftStatementWriter) throws -> Void,
            else: ((_ writer: SwiftStatementWriter) throws -> Void)? = nil) rethrows {
        try writeIf(conditions: [condition], then: then, else: `else`)
    }
}