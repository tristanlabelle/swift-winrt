protocol SwiftSyntaxWriter {
    var codeWriter: CodeWriter { get }
}

protocol SwiftTypeDeclarationWriter: SwiftSyntaxWriter {}
extension SwiftTypeDeclarationWriter {
    func writeClass(visibility: SwiftVisibility = .implicit, name: String, body: (SwiftRecordBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("class ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    func writeStruct(visibility: SwiftVisibility = .implicit, name: String, body: (SwiftRecordBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("struct ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    func writeEnum(visibility: SwiftVisibility = .implicit, name: String, body: (SwiftEnumBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("enum ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    func writeTypeAlias(visibility: SwiftVisibility = .implicit, name: String, target: String) {
        writeVisibility(visibility)
        codeWriter.write("typealias ")
        writeIdentifier(name)
        codeWriter.write(" = ")
        codeWriter.write(target, endLine: true)
    }
}

struct SwiftFileWriter: SwiftTypeDeclarationWriter {
    var codeWriter: CodeWriter

    func writeImport(module: String) {
        codeWriter.write("import ")
        codeWriter.write(module, endLine: true)
    }

    func writeProtocol(visibility: SwiftVisibility = .implicit, name: String, members: (SwiftProtocolBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("protocol ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            members(.init(codeWriter: $0))
        }
    }
}

struct SwiftProtocolBodyWriter: SwiftSyntaxWriter {
    let codeWriter: CodeWriter

    func writeProperty(
        static: Bool = false,
        name: String,
        type: String,
        set: Bool = false) {

        if `static` { codeWriter.write("static ") }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        codeWriter.write(type)
        codeWriter.write(" { get")
        if set { codeWriter.write(" set") }
        codeWriter.write(" }", endLine: true)
    }

    func writeFunc(
        static: Bool = false,
        name: String,
        parameters: (inout SwiftParameterListWriter) -> Void = { _ in },
        throws: Bool = false,
        returnType: String? = nil) {

        writeFuncHeader(
            visibility: .implicit,
            static: `static`,
            name: name,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        codeWriter.endLine()
    }
}

struct SwiftParameterListWriter: SwiftSyntaxWriter {
    let codeWriter: CodeWriter
    var first: Bool = true

    mutating func writeParameter(label: String? = nil, name: String, type: String, defaultValue: String? = nil) {
        if first {
            first = false
        } else {
            codeWriter.write(", ")
        }
        if let label {
            writeIdentifier(label)
            codeWriter.write(" ")
        }
        writeIdentifier(name)
        codeWriter.write(": ")
        codeWriter.write(type)
        if let defaultValue {
            codeWriter.write(" = ")
            codeWriter.write(defaultValue)
        }
    }
}

struct SwiftRecordBodyWriter: SwiftTypeDeclarationWriter {
    var codeWriter: CodeWriter

    func writeStoredProperty(
        visibility: SwiftVisibility = .implicit,
        privateVisibility: SwiftVisibility = .implicit,
        static: Bool = false,
        `let`: Bool,
        name: String,
        type: String,
        defaultValue: String? = nil) {

        writeVisibility(visibility)
        if privateVisibility != .implicit {
            codeWriter.write("private(")
            writeVisibility(privateVisibility)
            codeWriter.write(") ")
        }
        if `static` {
            codeWriter.write("static ")
        }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        codeWriter.write(type)
        if let defaultValue {
            codeWriter.write(" = ")
            codeWriter.write(defaultValue)
        }
        codeWriter.endLine()
    }

    func writeProperty(
        visibility: SwiftVisibility = .implicit, static: Bool = false,
        name: String, type: String,
        get: (inout SwiftStatementWriter) -> Void,
        set: ((inout SwiftStatementWriter) -> Void)? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        codeWriter.write(type)
        codeWriter.writeMultilineBlock() {
            if let set {
                $0.writeMultilineBlock("get") {
                    var statementWriter = SwiftStatementWriter(codeWriter: $0)
                    get(&statementWriter)
                }
                $0.writeMultilineBlock("set") {
                    var statementWriter = SwiftStatementWriter(codeWriter: $0)
                    set(&statementWriter)
                }
            }
            else {
                var statementWriter = SwiftStatementWriter(codeWriter: $0)
                get(&statementWriter)
            }
        }
    }

    func writeFunc(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        name: String,
        parameters: (inout SwiftParameterListWriter) -> Void = { _ in },
        throws: Bool = false,
        returnType: String? = nil,
        body: (inout SwiftStatementWriter) -> Void) {

        writeFuncHeader(
            visibility: visibility,
            static: `static`,
            name: name,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        codeWriter.writeMultilineBlock() {
            var statementWriter = SwiftStatementWriter(codeWriter: $0)
            body(&statementWriter)
        }
    }
}

struct SwiftEnumBodyWriter: SwiftTypeDeclarationWriter {
    let codeWriter: CodeWriter

    func writeCase(name: String, defaultValue: String? = nil) {
        codeWriter.write("case ")
        writeIdentifier(name)

        if let defaultValue {
            codeWriter.write(" = ")
            codeWriter.write(defaultValue)
        }

        codeWriter.endLine()
    }
}

struct SwiftStatementWriter: SwiftSyntaxWriter {
    let codeWriter: CodeWriter

    func writeFatalError(_ message: String? = nil) {
        codeWriter.write("fatalError(")
        if let message {
            codeWriter.write("\"")
            codeWriter.write(message)
            codeWriter.write("\"")
        }
        codeWriter.write(")", endLine: true)
    }
}

enum SwiftVisibility {
    case implicit
    case `internal`
    case `private`
    case `fileprivate`
    case `public`
    case `open`
}

extension SwiftSyntaxWriter {
    func writeFuncHeader(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        name: String,
        parameters: (inout SwiftParameterListWriter) -> Void = { _ in },
        throws: Bool = false,
        returnType: String? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("func ")
        writeIdentifier(name)
        codeWriter.write("(")

        var parameterListWriter = SwiftParameterListWriter(codeWriter: codeWriter)
        parameters(&parameterListWriter)

        codeWriter.write(")")
        if `throws` {
            codeWriter.write(" throws")
        }
        if let returnType {
            codeWriter.write(" -> ")
            codeWriter.write(returnType)
        }
    }

    fileprivate func writeVisibility(_ visibility: SwiftVisibility?, trailingSpace: Bool = true) {
        switch visibility {
            case .implicit: return
            case .internal: codeWriter.write("internal")
            case .private: codeWriter.write("private")
            case .fileprivate: codeWriter.write("fileprivate")
            case .public: codeWriter.write("public")
            default: break
        }

        if trailingSpace { codeWriter.write(" ") }
    }

    fileprivate func writeIdentifier(_ identifier: String) {
        let keywords = [
            // Keywords used in declarations:
            "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func",
            "import", "init", "inout", "internal", "let", "open", "operator", "private",
            "precedencegroup", "protocol", "public", "rethrows", "static", "struct", "subscript", "typealias", "var",
            // Keywords used in statements:
            "break", "case", "catch", "continue", "default", "defer", "do", "else", "fallthrough",
            "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while",
            // Keywords used in expressions and types:
            "Any", "as", "await", "catch", "false", "is", "nil", "rethrows",
            "self", "Self", "super", "throw", "throws", "true", "try"
        ]

        if keywords.contains(identifier) {
            codeWriter.write("`")
            codeWriter.write(identifier)
            codeWriter.write("`")
        } else {
            codeWriter.write(identifier)
        }
    }
}