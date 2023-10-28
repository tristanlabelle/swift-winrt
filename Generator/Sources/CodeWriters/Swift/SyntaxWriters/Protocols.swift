extension SwiftSourceFileWriter {
    public func writeProtocol(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        bases: [SwiftType] = [],
        whereClauses: [String] = [],
        members: (SwiftProtocolBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("protocol ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(bases)
        if !whereClauses.isEmpty {
            output.write(" where ")
            output.write(whereClauses.joined(separator: ", "))
        }
        try output.writeBracedIndentedBlock() {
            try members(.init(output: output))
        }
    }
}

public struct SwiftProtocolBodyWriter: SwiftSyntaxWriter {
    public let output: IndentedTextOutputStream

    public func writeAssociatedType(name: String) {
        var output = output
        output.beginLine(grouping: .withName("associatedtype"))
        output.write("associatedtype ")
        SwiftIdentifier.write(name, to: &output)
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
        SwiftIdentifier.write(name, to: &output)
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