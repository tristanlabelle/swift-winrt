public protocol SyntaxWriter {
    var codeWriter: CodeWriter { get }
}

public protocol TypeDeclarationWriter: SyntaxWriter {}
extension TypeDeclarationWriter {
    public func writeClass(visibility: Visibility = .implicit, name: String, body: (RecordBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("class ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    public func writeStruct(visibility: Visibility = .implicit, name: String, body: (RecordBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("struct ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    public func writeEnum(visibility: Visibility = .implicit, name: String, body: (EnumBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("enum ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            body(.init(codeWriter: $0))
        }
    }

    public func writeTypeAlias(visibility: Visibility = .implicit, name: String, target: String) {
        writeVisibility(visibility)
        codeWriter.write("typealias ")
        writeIdentifier(name)
        codeWriter.write(" = ")
        codeWriter.write(target, endLine: true)
    }
}

public struct FileWriter: TypeDeclarationWriter {
    public let codeWriter: CodeWriter

    public init(codeWriter: CodeWriter) {
        self.codeWriter = codeWriter
    }

    public func writeImport(module: String) {
        codeWriter.write("import ")
        codeWriter.write(module, endLine: true)
    }

    public func writeProtocol(visibility: Visibility = .implicit, name: String, members: (ProtocolBodyWriter) -> Void) {
        writeVisibility(visibility)
        codeWriter.write("protocol ")
        writeIdentifier(name)
        codeWriter.writeMultilineBlock() {
            members(.init(codeWriter: $0))
        }
    }
}

public struct ProtocolBodyWriter: SyntaxWriter {
    public let codeWriter: CodeWriter

    public func writeProperty(
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

    public func writeFunc(
        static: Bool = false,
        name: String,
        parameters: (inout ParameterListWriter) -> Void = { _ in },
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

public struct ParameterListWriter: SyntaxWriter {
    public let codeWriter: CodeWriter
    private var first: Bool = true

    init(codeWriter: CodeWriter) {
        self.codeWriter = codeWriter
    }

    public mutating func writeParameter(label: String? = nil, name: String, type: String, defaultValue: String? = nil) {
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

public struct RecordBodyWriter: TypeDeclarationWriter {
    public let codeWriter: CodeWriter

    public func writeStoredProperty(
        visibility: Visibility = .implicit,
        privateVisibility: Visibility = .implicit,
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

    public func writeProperty(
        visibility: Visibility = .implicit, static: Bool = false,
        name: String, type: String,
        get: (inout StatementWriter) -> Void,
        set: ((inout StatementWriter) -> Void)? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        codeWriter.write(type)
        codeWriter.writeMultilineBlock() {
            if let set {
                $0.writeMultilineBlock("get") {
                    var statementWriter = StatementWriter(codeWriter: $0)
                    get(&statementWriter)
                }
                $0.writeMultilineBlock("set") {
                    var statementWriter = StatementWriter(codeWriter: $0)
                    set(&statementWriter)
                }
            }
            else {
                var statementWriter = StatementWriter(codeWriter: $0)
                get(&statementWriter)
            }
        }
    }

    public func writeFunc(
        visibility: Visibility = .implicit,
        static: Bool = false,
        name: String,
        parameters: (inout ParameterListWriter) -> Void = { _ in },
        throws: Bool = false,
        returnType: String? = nil,
        body: (inout StatementWriter) -> Void) {

        writeFuncHeader(
            visibility: visibility,
            static: `static`,
            name: name,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        codeWriter.writeMultilineBlock() {
            var statementWriter = StatementWriter(codeWriter: $0)
            body(&statementWriter)
        }
    }
}

public struct EnumBodyWriter: TypeDeclarationWriter {
    public let codeWriter: CodeWriter

    public func writeCase(name: String, defaultValue: String? = nil) {
        codeWriter.write("case ")
        writeIdentifier(name)

        if let defaultValue {
            codeWriter.write(" = ")
            codeWriter.write(defaultValue)
        }

        codeWriter.endLine()
    }
}

public struct StatementWriter: SyntaxWriter {
    public let codeWriter: CodeWriter

    public func writeFatalError(_ message: String? = nil) {
        codeWriter.write("fatalError(")
        if let message {
            codeWriter.write("\"")
            codeWriter.write(message)
            codeWriter.write("\"")
        }
        codeWriter.write(")", endLine: true)
    }
}

public enum Visibility {
    case implicit
    case `internal`
    case `private`
    case `fileprivate`
    case `public`
    case `open`
}

extension SyntaxWriter {
    public func writeFuncHeader(
        visibility: Visibility = .implicit,
        static: Bool = false,
        name: String,
        parameters: (inout ParameterListWriter) -> Void = { _ in },
        throws: Bool = false,
        returnType: String? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("func ")
        writeIdentifier(name)
        codeWriter.write("(")

        var parameterListWriter = ParameterListWriter(codeWriter: codeWriter)
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

    fileprivate func writeVisibility(_ visibility: Visibility?, trailingSpace: Bool = true) {
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