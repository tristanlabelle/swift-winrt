public protocol SwiftSyntaxWriter {
    var output: IndentedTextOutputStream { get }
}

public enum SwiftVariableDeclarator: Hashable {
    case `let`
    case `var`
}

public protocol SwiftDeclarationWriter: SwiftSyntaxWriter {}

extension IndentedTextOutputStream {
    internal func writeBracedIndentedBlock(_ str: String = "", body: () throws -> Void) rethrows {
        try self.writeIndentedBlock(header: str + " {", footer: "}") {
            try body()
        }
    }
}

extension SwiftSyntaxWriter {
    public func writeCommentLine(_ comment: String, groupWithNext: Bool = true) {
        output.beginLine(grouping: .never)
        output.write("// ")
        output.write(comment)
        output.endLine(groupWithNext: groupWithNext)
    }

    internal func writeTypeParams(_ typeParams: [String]) {
        guard !typeParams.isEmpty else { return }
        var output = output
        output.write("<")
        for (index, typeParameter) in typeParams.enumerated() {
            if index > 0 { output.write(", ") }
            SwiftIdentifier.write(typeParameter, to: &output)
        }
        output.write(">")
    }

    internal func writeInheritanceClause(_ bases: [SwiftType]) {
        guard !bases.isEmpty else { return }
        var output = output
        output.write(": ")
        for (index, base) in bases.enumerated() {
            if index > 0 { output.write(", ") }
            base.write(to: &output)
        }
    }

    internal func writeParams(_ params: [SwiftParam]) {
        var output = output
        output.write("(")
        for (index, parameter) in params.enumerated() {
            if index > 0 { output.write(", ") }
            parameter.write(to: &output)
        }
        output.write(")")
    }

    internal func writeFuncHeader(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        override: Bool = false,
        name: String,
        typeParams: [String] = [],
        params: [SwiftParam] = [],
        async: Bool = false,
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        if `override` { output.write("override ") }
        output.write("func ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
        writeParams(params)
        if `async` { output.write(" async") }
        if `throws` { output.write(" throws") }
        if let returnType {
            output.write(" -> ")
            returnType.write(to: &output)
        }
    }
}