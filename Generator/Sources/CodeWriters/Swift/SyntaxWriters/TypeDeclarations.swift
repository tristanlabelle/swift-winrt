public struct SwiftTypeDefinitionWriter: SwiftDeclarationWriter {
    public let output: LineBasedTextOutputStream
}

extension SwiftDeclarationWriter {
    public func writeMarkComment(_ text: String) {
        output.beginLine(group: .alone)
        output.write("// MARK: ")
        output.write(text)
        output.endLine()
    }

    public func writeClass(
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        visibility: SwiftVisibility = .implicit,
        final: Bool = false,
        name: String,
        typeParams: [String] = [],
        base: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(group: .alone)
        if let documentation { writeDocumentationComment(documentation) }
        writeAttributes(attributes)
        visibility.write(to: &output, trailingSpace: true)
        if final { output.write("final ") }
        output.write("class ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
        writeInheritanceClause([base].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
        }
    }

    public func writeStruct(
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParams: [String] = [],
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(group: .alone)
        if let documentation { writeDocumentationComment(documentation) }
        writeAttributes(attributes)
        visibility.write(to: &output, trailingSpace: true)
        output.write("struct ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
        writeInheritanceClause(protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
        }
    }

    public func writeEnum(
        documentation: SwiftDocumentationComment? = nil,
        attributes: [SwiftAttribute] = [],
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParams: [String] = [],
        rawValueType: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(group: .alone)
        if let documentation { writeDocumentationComment(documentation) }
        writeAttributes(attributes)
        visibility.write(to: &output, trailingSpace: true)
        output.write("enum ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
        writeInheritanceClause([rawValueType].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
        }
    }

    public func writeTypeAlias(
        documentation: SwiftDocumentationComment? = nil,
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParams: [String] = [],
        target: SwiftType) {

        var output = output
        if let documentation { writeDocumentationComment(documentation) }
        output.beginLine(group: .named("typealias"))
        visibility.write(to: &output, trailingSpace: true)
        output.write("typealias ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParams(typeParams)
        output.write(" = ")
        target.write(to: &output)
        output.endLine()
    }
}