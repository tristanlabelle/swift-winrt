public protocol SyntaxWriter {
    var output: IndentedTextOutputStream { get }
}

public struct SourceFileWriter: TypeDeclarationWriter {
    public let output: IndentedTextOutputStream

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = IndentedTextOutputStream(inner: output, indent: indent)
    }

    public func writeImport(module: String) {
        output.beginLine(grouping: .with("import"))
        output.write("import ")
        output.write(module, endLine: true)
    }

    public func writeProtocol(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        bases: [SwiftType] = [],
        members: (ProtocolBodyWriter) -> Void) {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("protocol ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(bases)
        output.writeBracedIndentedBlock() {
            members(.init(output: output))
        }
    }
}

public protocol TypeDeclarationWriter: SyntaxWriter {}
extension TypeDeclarationWriter {
    public func writeClass(
        visibility: Visibility = .implicit,
        final: Bool = false,
        name: String,
        typeParameters: [String] = [],
        base: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        body: (RecordBodyWriter) -> Void) {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        if final { output.write("final ") }
        output.write("class ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([base].compactMap { $0 } + protocolConformances)
        output.writeBracedIndentedBlock() {
            body(.init(output: output))
        }
    }

    public func writeStruct(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        protocolConformances: [SwiftType] = [],
        body: (RecordBodyWriter) -> Void) {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("struct ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(protocolConformances)
        output.writeBracedIndentedBlock() {
            body(.init(output: output))
        }
    }

    public func writeEnum(
        visibility: Visibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        rawValueType: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        body: (EnumBodyWriter) -> Void) {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("enum ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([rawValueType].compactMap { $0 } + protocolConformances)
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
        output.beginLine(grouping: .with("typealias"))
        visibility.write(to: &output, trailingSpace: true)
        output.write("typealias ")
        writeIdentifier(name, to: &output)
        writeTypeParameters(typeParameters)
        output.write(" = ")
        target.write(to: &output)
        output.endLine()
    }
}

public struct ProtocolBodyWriter: SyntaxWriter {
    public let output: IndentedTextOutputStream

    public func writeAssociatedType(name: String) {
        var output = output
        output.beginLine(grouping: .with("associatedtype"))
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
        output.beginLine(grouping: .with("protocolProperty"))
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

        output.beginLine(grouping: .with("protocolFunc"))
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
    public let output: IndentedTextOutputStream

    public func writeStoredProperty(
        visibility: Visibility = .implicit,
        privateVisibility: Visibility = .implicit,
        static: Bool = false,
        `let`: Bool,
        name: String,
        type: SwiftType,
        defaultValue: String? = nil) {

        var output = output
        output.beginLine(grouping: .with("storedProperty"))
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
        output.beginLine(grouping: .never)
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

        output.beginLine(grouping: .never)
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
        output.beginLine(grouping: .never)
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
    public let output: IndentedTextOutputStream

    public func writeCase(name: String, rawValue: String? = nil) {
        var output = output
        output.beginLine(grouping: .with("case"))
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
    public let output: IndentedTextOutputStream

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

extension IndentedTextOutputStream {
    public func writeBracedIndentedBlock(_ str: String = "", body: () -> Void) {
        self.writeIndentedBlock(header: str + " {", footer: "}") {
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

    fileprivate func writeInheritanceClause(_ bases: [SwiftType]) {
        guard !bases.isEmpty else { return }
        var output = output
        output.write(": ")
        for (index, base) in bases.enumerated() {
            if index > 0 { output.write(", ") }
            base.write(to: &output)
        }
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