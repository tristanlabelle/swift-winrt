extension SwiftDeclarationWriter {
    public func writeStoredProperty(
        documentation: SwiftDocumentationComment? = nil,
        visibility: SwiftVisibility = .implicit,
        setVisibility: SwiftVisibility = .implicit,
        static: Bool = false,
        declarator: SwiftVariableDeclarator,
        `lazy`: Bool = false,
        name: String,
        type: SwiftType? = nil,
        initialValue: String? = nil,
        initializer: ((LineBasedTextOutputStream) throws -> Void)? = nil) rethrows {

        precondition(initialValue == nil || initializer == nil)

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named("storedProperty"))
        visibility.write(to: &output, trailingSpace: true)
        if setVisibility != .implicit {
            setVisibility.write(to: &output, trailingSpace: false)
            output.write("(set) ")
        }
        if `static` { output.write("static ") }
        output.write(declarator == .let ? "let " : "var ")
        if `lazy` { output.write("lazy ") }
        SwiftIdentifier.write(name, to: &output)
        if let type {
            output.write(": ")
            type.write(to: &output)
        }
        if let initialValue {
            output.write(" = ")
            output.write(initialValue)
        }
        else if initializer != nil {
            output.write(" = ")
            try initializer?(output)
        }
        output.endLine()
    }

    public func writeComputedProperty(
        documentation: SwiftDocumentationComment? = nil,
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
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .alone)
        visibility.write(to: &output, trailingSpace: true)
        if `static` { output.write("static ") }
        if `override` { output.write("override ") }
        output.write("var ")
        SwiftIdentifier.write(name, to: &output)
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
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        visibility: SwiftVisibility = .implicit,
        static: Bool = false,
        override: Bool = false,
        mutating: Bool = false,
        operatorLocation: SwiftOperatorLocation? = nil,
        name: String,
        typeParams: [String] = [],
        params: [SwiftParam] = [],
        async: Bool = false,
        throws: Bool = false,
        returnType: SwiftType? = nil,
        body: (inout SwiftStatementWriter) throws -> Void) rethrows {

        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .alone)
        writeFuncHeader(
            attributes: attributes,
            visibility: visibility,
            static: `static`,
            override: `override`,
            mutating: `mutating`,
            operatorLocation: operatorLocation,
            name: name,
            typeParams: typeParams,
            params: params,
            async: `async`,
            throws: `throws`,
            returnType: returnType)
        try output.writeBracedIndentedBlock() {
            var statementWriter = SwiftStatementWriter(output: output)
            try body(&statementWriter)
        }
    }

    public func writeEnumCase(
        documentation: SwiftDocumentationComment? = nil,
        name: String,
        rawValue: String? = nil) {

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named("case"))
        output.write("case ")
        SwiftIdentifier.write(name, to: &output)

        if let rawValue {
            output.write(" = ")
            output.write(rawValue)
        }

        output.endLine()
    }

    public func writeInit(
        documentation: SwiftDocumentationComment? = nil,
        visibility: SwiftVisibility = .implicit,
        required: Bool = false,
        convenience: Bool = false,
        override: Bool = false,
        failable: Bool = false,
        genericParams: [String] = [],
        params: [SwiftParam] = [],
        throws: Bool = false,
        body: (inout SwiftStatementWriter) throws -> Void) rethrows {

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .alone)
        visibility.write(to: &output, trailingSpace: true)
        if `required` { output.write("required ") }
        if `convenience` { output.write("convenience ") }
        if `override` { output.write("override ") }
        output.write("init")
        if failable { output.write("?") }
        if !genericParams.isEmpty {
            output.write("<")
            output.write(genericParams.joined(separator: ", "))
            output.write(">")
        }
        writeParams(params)
        if `throws` {
            output.write(" throws")
        }

        try output.writeBracedIndentedBlock() {
            var statementWriter = SwiftStatementWriter(output: output)
            try body(&statementWriter)
        }
    }

    public func writeDeinit(body: (inout SwiftStatementWriter) throws -> Void) rethrows {
        output.beginLine(group: .alone)
        output.write("deinit")
        try output.writeBracedIndentedBlock() {
            var statementWriter = SwiftStatementWriter(output: output)
            try body(&statementWriter)
        }
    }
}