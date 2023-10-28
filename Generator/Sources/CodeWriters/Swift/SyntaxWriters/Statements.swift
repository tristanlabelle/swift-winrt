public struct SwiftStatementWriter: SwiftSyntaxWriter {
    public let output: IndentedTextOutputStream

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
        output.writeLine()
    }

    public func writeStatement(_ code: String) {
        output.write(code, endLine: true)
    }
}