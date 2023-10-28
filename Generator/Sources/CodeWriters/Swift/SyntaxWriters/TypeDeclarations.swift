public struct SwiftTypeDefinitionWriter: SwiftDeclarationWriter {
    public let output: IndentedTextOutputStream
}

extension SwiftDeclarationWriter {
    public func writeClass(
        visibility: SwiftVisibility = .implicit,
        final: Bool = false,
        name: String,
        typeParameters: [String] = [],
        base: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        if final { output.write("final ") }
        output.write("class ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([base].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
        }
    }

    public func writeStruct(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("struct ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause(protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
        }
    }

    public func writeEnum(
        visibility: SwiftVisibility = .implicit,
        name: String,
        typeParameters: [String] = [],
        rawValueType: SwiftType? = nil,
        protocolConformances: [SwiftType] = [],
        definition: (SwiftTypeDefinitionWriter) throws -> Void) rethrows {

        var output = output
        output.beginLine(grouping: .never)
        visibility.write(to: &output, trailingSpace: true)
        output.write("enum ")
        SwiftIdentifier.write(name, to: &output)
        writeTypeParameters(typeParameters)
        writeInheritanceClause([rawValueType].compactMap { $0 } + protocolConformances)
        try output.writeBracedIndentedBlock() {
            try definition(.init(output: output))
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
        SwiftIdentifier.write(name, to: &output)
        writeTypeParameters(typeParameters)
        output.write(" = ")
        target.write(to: &output)
        output.endLine()
    }
}