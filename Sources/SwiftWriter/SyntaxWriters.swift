public protocol SyntaxWriter {
    var output: CodeOutputStream { get }
}

public protocol TypeDeclarationWriter: SyntaxWriter {}
extension TypeDeclarationWriter {
    public func writeClass(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        body: (RecordBodyWriter) -> Void) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("class ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        output.writeBracedIndentedBlock() {
            body(.init(output: output))
        }
    }

    public func writeStruct(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        body: (RecordBodyWriter) -> Void) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("struct ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        output.writeBracedIndentedBlock() {
            body(.init(output: output))
        }
    }

    public func writeEnum(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        rawValueType: SwiftType? = nil,
        body: (EnumBodyWriter) -> Void) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("enum ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        if let rawValueType {
            output.write(": ")
            rawValueType.write(to: &output)
        }
        output.writeBracedIndentedBlock() {
            body(.init(output: output))
        }
    }

    public func writeTypeAlias(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        target: SwiftType) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("typealias ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        output.write(" = ")
        target.write(to: &output)
        output.endLine(smartTrailingBlankLine: true)
    }
}

public struct FileWriter: TypeDeclarationWriter {
    public let output: CodeOutputStream

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = CodeOutputStream(inner: output, indent: indent)
    }

    public func writeImport(module: String) {
        output.write("import ")
        output.write(module, endLine: true, smartTrailingBlankLine: true)
    }

    public func writeProtocol(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        members: (ProtocolBodyWriter) -> Void) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("protocol ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        output.writeBracedIndentedBlock() {
            members(.init(output: output))
        }
    }
}

public struct ProtocolBodyWriter: SyntaxWriter {
    public let output: CodeOutputStream

    public func writeAssociatedType(name: String) {
        var output = output
        output.write("associatedtype ")
        writeIdentifier(name, to: &output)
        output.endLine()
    }

    public func writeProperty(
        static: Bool = false,
        name: String,
        type: SwiftType,
        set: Bool = false) {

        var output = output
        if `static` { output.write("static ") }
        output.write("var ")
        writeIdentifier(name, to: &output)
        output.write(": ")
        type.write(to: &output)
        output.write(" { get")
        if set { output.write(" set") }
        output.write(" }", endLine: true)
    }

    public func writeFunc(
        static: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        writeFuncHeader(
            visibility: .implicit,
            static: `static`,
            name: name,
            typeParameters: typeParameters,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        output.endLine()
    }
}

public struct RecordBodyWriter: TypeDeclarationWriter {
    public let output: CodeOutputStream

    public func writeStoredProperty(
        visibility: Visibility = .implicit,
        privateVisibility: Visibility = .implicit,
        static: Bool = false,
        `let`: Bool,
        name: String,
        type: SwiftType,
        defaultValue: String? = nil) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        if privateVisibility != .implicit {
            privateVisibility.write(to: &output, trailingSpace: false)
            output.write("(set) ")
        }
        if `static` {
            output.write("static ")
        }
        output.write("var ")
        writeIdentifier(name, to: &output)
        output.write(": ")
        type.write(to: &output)
        if let defaultValue {
            output.write(" = ")
            output.write(defaultValue)
        }
        output.endLine()
    }

    public func writeProperty(
        visibility: Visibility = .implicit, static: Bool = false,
        name: String, type: SwiftType,
        get: (inout StatementWriter) -> Void,
        set: ((inout StatementWriter) -> Void)? = nil) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        output.write("var ")
        writeIdentifier(name, to: &output)
        output.write(": ")
        type.write(to: &output)
        output.writeBracedIndentedBlock() {
            if let set {
                output.writeBracedIndentedBlock("get") {
                    var statementWriter = StatementWriter(output: output)
                    get(&statementWriter)
                }
                output.writeBracedIndentedBlock("set") {
                    var statementWriter = StatementWriter(output: output)
                    set(&statementWriter)
                }
            }
            else {
                var statementWriter = StatementWriter(output: output)
                get(&statementWriter)
            }
        }
    }

    public func writeFunc(
        visibility: Visibility = .implicit,
        static: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil,
        body: (inout StatementWriter) -> Void) {

        writeFuncHeader(
            visibility: visibility,
            static: `static`,
            name: name,
            typeParameters: typeParameters,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        output.writeBracedIndentedBlock() {
            var statementWriter = StatementWriter(output: output)
            body(&statementWriter)
        }
    }


    public func writeInit(
        visibility: Visibility = .implicit,
        failable: Bool = false,
        parameters: [Parameter],
        throws: Bool = false,
        body: (inout StatementWriter) -> Void) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        output.write("init")
        if failable { output.write("?") }
        writeParameters(parameters)
        if `throws` {
            output.write(" throws")
        }

        output.writeBracedIndentedBlock() {
            var statementWriter = StatementWriter(output: output)
            body(&statementWriter)
        }
    }
}

public struct EnumBodyWriter: TypeDeclarationWriter {
    public let output: CodeOutputStream

    public func writeCase(name: String, rawValue: String? = nil) {
        var output = output
        output.write("case ")
        writeIdentifier(name, to: &output)

        if let rawValue {
            output.write(" = ")
            output.write(rawValue)
        }

        output.endLine()
    }
}

public struct StatementWriter: SyntaxWriter {
    public let output: CodeOutputStream

    public func writeFatalError(_ message: String? = nil) {
        output.write("fatalError(")
        if let message {
            output.write("\"")
            output.write(message)
            output.write("\"")
        }
        output.write(")", endLine: true)
    }
}

extension CodeOutputStream {
    public func writeBracedIndentedBlock(_ str: String = "", body: () -> Void) {
        self.writeIndentedBlock(header: str + " {", footer: "}", smartTrailingBlankLine: true) {
            body()
        }
    }
}

extension SyntaxWriter {
    fileprivate func writeTypeParameters(_ typeParameters: [String]) {
        guard !typeParameters.isEmpty else { return }
        var output = output
        output.write("<")
        for (index, typeParameter) in typeParameters.enumerated() {
            if index > 0 { output.write(", ") }
            writeIdentifier(typeParameter, to: &output)
        }
        output.write(">")
    }

    fileprivate func writeParameters(_ parameters: [Parameter]) {
        var output = output
        output.write("(")
        for (index, parameter) in parameters.enumerated() {
            if index > 0 { output.write(", ") }
            parameter.write(to: &output)
        }
        output.write(")")
    }

    fileprivate func writeFuncHeader(
        visibility: Visibility = .implicit,
        static: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [Parameter],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        output.write("func ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        writeParameters(parameters)
        if `throws` {
            output.write(" throws")
        }
        if let returnType {
            output.write(" -> ")
            returnType.write(to: &output)
        }
    }
}