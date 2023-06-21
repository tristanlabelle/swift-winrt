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

    public func writeTypeAlias(visibility: Visibility = .implicit, name: String, target: SwiftType) {
        writeVisibility(visibility)
        codeWriter.write("typealias ")
        writeIdentifier(name)
        codeWriter.write(" = ")
        writeType(target)
        codeWriter.endLine()
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
        type: SwiftType,
        set: Bool = false) {

        if `static` { codeWriter.write("static ") }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        writeType(type)
        codeWriter.write(" { get")
        if set { codeWriter.write(" set") }
        codeWriter.write(" }", endLine: true)
    }

    public func writeFunc(
        static: Bool = false,
        name: String,
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

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

public struct Parameter {
    public var label: String?
    public var name: String
    public var type: SwiftType
    public var defaultValue: String?

    public init(label: String? = nil, name: String, type: SwiftType, defaultValue: String? = nil) {
        self.label = label
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
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
        type: SwiftType,
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
        writeType(type)
        if let defaultValue {
            codeWriter.write(" = ")
            codeWriter.write(defaultValue)
        }
        codeWriter.endLine()
    }

    public func writeProperty(
        visibility: Visibility = .implicit, static: Bool = false,
        name: String, type: SwiftType,
        get: (inout StatementWriter) -> Void,
        set: ((inout StatementWriter) -> Void)? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("var ")
        writeIdentifier(name)
        codeWriter.write(": ")
        writeType(type)
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
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil,
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

    public func writeCase(name: String, rawValue: String? = nil) {
        codeWriter.write("case ")
        writeIdentifier(name)

        if let rawValue {
            codeWriter.write(" = ")
            codeWriter.write(rawValue)
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
    public func writeParameterList(_ parameters: [Parameter]) {
        for (index, parameter) in parameters.enumerated() {
            if index > 0 { codeWriter.write(", ") }
            if let label = parameter.label {
                writeIdentifier(label)
                codeWriter.write(" ")
            }
            writeIdentifier(parameter.name)
            codeWriter.write(": ")
            writeType(parameter.type)
            if let defaultValue = parameter.defaultValue {
                codeWriter.write(" = ")
                codeWriter.write(defaultValue)
            }
        }
    }

    public func writeFuncHeader(
        visibility: Visibility = .implicit,
        static: Bool = false,
        name: String,
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        writeVisibility(visibility)
        if `static` { codeWriter.write("static ") }
        codeWriter.write("func ")
        writeIdentifier(name)
        codeWriter.write("(")
        writeParameterList(parameters)
        codeWriter.write(")")
        if `throws` {
            codeWriter.write(" throws")
        }
        if let returnType {
            codeWriter.write(" -> ")
            writeType(returnType)
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

    fileprivate func writeType(_ type: SwiftType) {
        switch type {
            case let .identifierChain(chain):
                if chain.protocolModifier == .existential {
                    codeWriter.write("any ")
                }
                else if chain.protocolModifier == .opaque {
                    codeWriter.write("some ")
                }

                for (index, item) in chain.items.enumerated() {
                    if index > 0 { codeWriter.write(".") }
                    writeIdentifier(item.name)
                    guard !item.genericArgs.isEmpty else { continue }
                    codeWriter.write("<")
                    for (index, arg) in item.genericArgs.enumerated() {
                        if index > 0 { codeWriter.write(", ") }
                        writeType(arg)
                    }
                    codeWriter.write(">")
                }

            case let .`optional`(wrapped, forceUnwrap):
                let parenthesized: Bool
                if case let .identifierChain(chain) = wrapped, chain.protocolModifier != nil {
                    codeWriter.write("(")
                    parenthesized = true
                }
                else {
                    parenthesized = false
                }
                writeType(wrapped)
                if parenthesized { codeWriter.write(")") }
                codeWriter.write(forceUnwrap ? "!" : "?")

            case let .tuple(elements):
                codeWriter.write("(")
                for (index, element) in elements.enumerated() {
                    if index > 0 { codeWriter.write(", ") }
                    writeType(element)
                }
                codeWriter.write(")")

            case let .array(element):
                codeWriter.write("[")
                writeType(element)
                codeWriter.write("]")

            case let .dictionary(key, value):
                codeWriter.write("[")
                writeType(key)
                codeWriter.write(": ")
                writeType(value)
                codeWriter.write("]")

            case let .function(params, `throws`, returnType):
                codeWriter.write("(")
                for (index, param) in params.enumerated() {
                    if index > 0 { codeWriter.write(", ") }
                    writeType(param)
                }
                codeWriter.write(")")
                if `throws` { codeWriter.write(" throws") }
                codeWriter.write(" -> ")
                writeType(returnType)
        }
    }
}