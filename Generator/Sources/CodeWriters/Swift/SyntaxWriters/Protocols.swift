extension SwiftSourceFileWriter {
    public func writeProtocol(
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParams: [String] = [],
        bases: [SwiftType] = [],
        whereClauses: [String] = [],
        members: (SwiftProtocolBodyWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(group: .alone)
        if let documentation = documentation { writeDocumentationComment(documentation) }
        writeAttributes(attributes)
        visibility.write(to: &output, trailingSpace: true)
        output.write("protocol ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
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
    public let output: LineBasedTextOutputStream

    public func writeAssociatedType(
        documentation: SwiftDocumentationComment? = nil,
        name: String) {

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named("associatedtype"))
        output.write("associatedtype ")
        SwiftIdentifier.write(name, to: &output)
        output.endLine()
    }

    public func writeProperty(
        documentation: SwiftDocumentationComment? = nil,
        static: Bool = false,
        name: String,
        type: SwiftType,
        throws: Bool = false,
        set: Bool = false) {

        precondition(!set || !`throws`)

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named("protocolProperty"))
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
        groupAsProperty: Bool = false,
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        static: Bool = false,
        mutating: Bool = false,
        operatorLocation: SwiftOperatorLocation? = nil,
        name: String,
        typeParams: [String] = [],
        params: [SwiftParam] = [],
        async: Bool = false,
        throws: Bool = false,
        returnType: SwiftType? = nil) {

        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named(groupAsProperty ? "protocolProperty" : "protocolFunc"))
        writeFuncHeader(
            attributes: attributes,
            visibility: .implicit,
            static: `static`,
            mutating: `mutating`,
            operatorLocation: operatorLocation,
            name: name,
            typeParams: typeParams,
            params: params,
            async: `async`,
            throws: `throws`,
            returnType: returnType)
        output.endLine()
    }
}