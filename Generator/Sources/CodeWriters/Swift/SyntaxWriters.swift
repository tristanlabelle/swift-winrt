public protocol SwiftSyntaxWriter {
    var output: IndentedTextOutputStream { get }
}

public struct SwiftSourceFileWriter: SwiftTypeDeclarationWriter {
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

    public func writeProtocol(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        bases: [SwiftType] = [],
        members: (SwiftProtocolBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("protocol ")
        SwiftIdentifiers.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(bases)
        try output.writeBracedIndentedBlock() {
            try members(.init(output: output))
        }
    }

    public func writeExtension(
        name: String,
        protocolConformances: [SwiftType] = [],
        members: (SwiftRecordBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        output.write("extension ")
        SwiftIdentifiers.write(name, to: &output)
        writeInheritanceClause(protocolConformances)
        try output.writeBracedIndentedBlock() {
            try members(.init(output: output))
        }
    }
}

public protocol SwiftTypeDeclarationWriter: SwiftSyntaxWriter {}

extension SwiftTypeDeclarationWriter {
    public func writeClass(
        visibility: SwiftVisibility = .implicit,
        final: Bool = false,
        name: String,
        typeParameters: [String] = [],
        base: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        body: (SwiftRecordBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        if final { output.write("final ") }
        output.write("class ")
        SwiftIdentifiers.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([base].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try body(.init(output: output))
        }
    }

    public func writeStruct(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        protocolConformances: [SwiftType] = [],
        body: (SwiftRecordBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("struct ")
        SwiftIdentifiers.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(protocolConformances)
        try output.writeBracedIndentedBlock() {
            try body(.init(output: output))
        }
    }

    public func writeEnum(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        rawValueType: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        body: (SwiftEnumBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("enum ")
        SwiftIdentifiers.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([rawValueType].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try body(.init(output: output))
        }
    }

    public func writeTypeAlias(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        target: SwiftType) {

        var output = output
        output.beginLine(grouping: .withName("typealias"))
        visibility.write(to: &output, trailingSpace: true)
        output.write("typealias ")
        SwiftIdentifiers.write(name, to: &output)
        writeTypeParameters(typeParameters)
        output.write(" = ")
        target.write(to: &output)
        output.endLine()
    }
}

public struct SwiftProtocolBodyWriter: SwiftSyntaxWriter {
    public let output: IndentedTextOutputStream

    public func writeAssociatedType(name: String) {
        var output = output
        output.beginLine(grouping: .withName("associatedtype"))
        output.write("associatedtype ")
        SwiftIdentifiers.write(name, to: &output)
        output.endLine()
    }

    public func writeProperty(
        static: Bool = false,
        name: String,
        type: SwiftType,
        throws: Bool = false,
        set: Bool = false) {

        precondition(!set || !`throws`)

        var output = output
        output.beginLine(grouping: .withName("protocolProperty"))
        if `static` { output.write("static ") }
        output.write("var ")
        SwiftIdentifiers.write(name, to: &output)
        output.write(": ")
        type.write(to: &output)
        output.write(" { get")
        if `throws` { output.write(" throws") }
        if set { output.write(" set") }
        output.write(" }", endLine: true)
    }

    public func writeFunc(
        isPropertySetter: Bool = false,
        static: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [SwiftParameter] = [],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        output.beginLine(grouping: .withName(isPropertySetter ? "protocolProperty" : "protocolFunc"))
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

public struct SwiftRecordBodyWriter: SwiftTypeDeclarationWriter {
    public let output: IndentedTextOutputStream

    public func writeStoredProperty(
        visibility: SwiftVisibility = .implicit,
        setVisibility: SwiftVisibility = .implicit,
        static: Bool = false,
        `let`: Bool = false,
        name: String,
        type: SwiftType? = nil,
        initializer: String? = nil) {

        var output = output
        output.beginLine(grouping: .withName("storedProperty"))
        visibility.write(to: &output, trailingSpace: true)
        if setVisibility != .implicit {
            setVisibility.write(to: &output, trailingSpace: false)
            output.write("(set) ")
        }
        if `static` { output.write("static ") }
        output.write(`let` ? "let " : "var ")
        SwiftIdentifiers.write(name, to: &output)
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

    public func writeComputedProperty(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        override: Bool = false,
        name: String,
        type: SwiftType,
        throws: Bool = false,
        get: (inout SwiftStatementWriter) throws -> Void,
        set: ((inout SwiftStatementWriter) throws -> Void)? = nil) rethrows {

        precondition(set == nil || !`throws`)

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        if `override` { output.write("override ") }
        output.write("var ")
        SwiftIdentifiers.write(name, to: &output)
        output.write(": ")
        type.write(to: &output)
        try output.writeBracedIndentedBlock() {
            if let set {
                try output.writeBracedIndentedBlock("get") {
                    var statementWriter = SwiftStatementWriter(output: output)
                    try get(&statementWriter)
                }
                try output.writeBracedIndentedBlock("set") {
                    var statementWriter = SwiftStatementWriter(output: output)
                    try set(&statementWriter)
                }
            }
            else if `throws` {
                try output.writeBracedIndentedBlock("get throws") {
                    var statementWriter = SwiftStatementWriter(output: output)
                    try get(&statementWriter)
                }
            }
            else {
                var statementWriter = SwiftStatementWriter(output: output)
                try get(&statementWriter)
            }
        }
    }

    public func writeFunc(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        override: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [SwiftParameter] = [],
        throws: Bool = false,
        returnType: SwiftType? = nil,
        body: (inout SwiftStatementWriter) throws -> Void) rethrows {

        output.beginLine(grouping: .never)
        writeFuncHeader(
            visibility: visibility,
            static: `static`,
            override: `override`,
            name: name,
            typeParameters: typeParameters,
            parameters: parameters,
            throws: `throws`,
            returnType: returnType)
        try output.writeBracedIndentedBlock() {
            var statementWriter = SwiftStatementWriter(output: output)
            try body(&statementWriter)
        }
    }

    public func writeInit(
        visibility: SwiftVisibility = .implicit,
        override: Bool = false,
        failable: Bool = false,
        parameters: [SwiftParameter] = [],
        throws: Bool = false,
        body: (inout SwiftStatementWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        if `override` { output.write("override ") }
        output.write("init")
        if failable { output.write("?") }
        writeParameters(parameters)
        if `throws` {
            output.write(" throws")
        }

        try output.writeBracedIndentedBlock() {
            var statementWriter = SwiftStatementWriter(output: output)
            try body(&statementWriter)
        }
    }
}

public struct SwiftEnumBodyWriter: SwiftTypeDeclarationWriter {
    public let output: IndentedTextOutputStream

    public func writeCase(name: String, rawValue: String? = nil) {
        var output = output
        output.beginLine(grouping: .withName("case"))
        output.write("case ")
        SwiftIdentifiers.write(name, to: &output)

        if let rawValue {
            output.write(" = ")
            output.write(rawValue)
        }

        output.endLine()
    }
}

public struct SwiftStatementWriter: SwiftSyntaxWriter {
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

    public func writeNotImplemented() {
        writeFatalError("Not implemented: \\(#function)")
    }

    public func writeStatement(_ code: String) {
        output.write(code, endLine: true)
    }
}

extension IndentedTextOutputStream {
    fileprivate func writeBracedIndentedBlock(_ str: String = "", body: () throws -> Void) rethrows {
        try self.writeIndentedBlock(header: str + " {", footer: "}") {
            try body()
        }
    }
}

extension SwiftSyntaxWriter {
    fileprivate func writeTypeParameters(_ typeParameters: [String]) {
        guard !typeParameters.isEmpty else { return }
        var output = output
        output.write("<")
        for (index, typeParameter) in typeParameters.enumerated() {
            if index > 0 { output.write(", ") }
            SwiftIdentifiers.write(typeParameter, to: &output)
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

    fileprivate func writeParameters(_ parameters: [SwiftParameter]) {
        var output = output
        output.write("(")
        for (index, parameter) in parameters.enumerated() {
            if index > 0 { output.write(", ") }
            parameter.write(to: &output)
        }
        output.write(")")
    }

    fileprivate func writeFuncHeader(
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        override: Bool = false,
        name: String,
        typeParameters: [String] = [],
        parameters: [SwiftParameter] = [],
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        var output = output
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        if `override` { output.write("override ") }
        output.write("func ")
        SwiftIdentifiers.write(name, to: &output)
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