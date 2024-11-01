import CodeWriters
import DotNetMetadata
import DotNetXMLDocs
import DotNetXMLDocsFromMetadata

extension Projection {
    public func getDocumentationComment(_ typeDefinition: TypeDefinition) -> SwiftDocumentationComment? {
        guard let assemblyDocumentation = assembliesToModules[typeDefinition.assembly]?.documentation else { return nil }
        return assemblyDocumentation.lookup(typeDefinition: typeDefinition).map(toDocumentationComment)
    }

    public func getDocumentationComment(_ member: Member, classFactoryKind: ClassFactoryKind? = nil, classDefinition: ClassDefinition? = nil) throws -> SwiftDocumentationComment? {
        try getMemberDocumentation(member, classFactoryKind: classFactoryKind, classDefinition: classDefinition)
            .map(toDocumentationComment)
    }

    public enum PropertyAccessor {
        case getter
        case setter
        case nonthrowingGetterSetter
    }

    public func getDocumentationComment(_ property: Property, accessor: PropertyAccessor, classDefinition: ClassDefinition? = nil) throws -> SwiftDocumentationComment? {
        guard var propertyDocumentation = try getMemberDocumentation(property, classDefinition: classDefinition) else { return nil }

        // Properties' values are supposed to be documented using <value>, but WinRT docs use <returns>.
        let valueDocumentation = propertyDocumentation.value ?? propertyDocumentation.returns

        propertyDocumentation.value = nil
        propertyDocumentation.returns = nil
        propertyDocumentation.params = [] // WinRT doesn't support indexers

        /// Replaces the prefix of a documentation text node
        func replacePrefix(_ text: DocumentationText, prefix: String, replacement: String) -> DocumentationText {
            guard let firstNode = text.nodes.first,
                    case .plain(let str) = firstNode,
                    str.hasPrefix(prefix) else { return text }

            let newStr = replacement + str.dropFirst(prefix.count)
            return DocumentationText(nodes: [.plain(newStr)] + text.nodes.dropFirst())
        }

        switch accessor {
            case .getter:
                // Prefer the <value> tag (describes the data)
                propertyDocumentation.summary = (valueDocumentation ?? propertyDocumentation.summary)
                    .map { replacePrefix($0, prefix: "Gets or sets ", replacement: "Gets ") }
            case .setter:
                // Prefer the <summary> tag (describes the operation)
                propertyDocumentation.summary = (propertyDocumentation.summary ?? valueDocumentation)
                    .map { replacePrefix($0, prefix: "Gets or sets ", replacement: "Sets ") }
                propertyDocumentation.params = valueDocumentation.map {
                    [ .init(name: "newValue", description:$0) ]
                } ?? []
            case .nonthrowingGetterSetter:
                // Prefer the <summary> tag (describes the operation)
                propertyDocumentation.summary = propertyDocumentation.summary ?? valueDocumentation

                if propertyDocumentation.remarks == nil {
                    propertyDocumentation.remarks = DocumentationText.plain("Treats exceptions as fatal errors.")
                }
        }

        return toDocumentationComment(propertyDocumentation)
    }

    public func getDocumentationComment(_ genericParam: GenericParam, typeDefinition: TypeDefinition) -> SwiftDocumentationComment? {
        let genericParamDocumentation = assembliesToModules[genericParam.assembly]?
            .documentation?
            .lookup(typeDefinition: typeDefinition)?
            .typeParams
            .first { $0.name == genericParam.name }
            .map { $0.description }
        guard let genericParamDocumentation, !genericParamDocumentation.nodes.isEmpty else { return nil }

        // Ignore if all whitespace
        if genericParamDocumentation.nodes.count == 1,
                case .plain(let text) = genericParamDocumentation.nodes[0],
                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }

        var documentationComment = SwiftDocumentationComment()
        documentationComment.summary = toBlocks(genericParamDocumentation)
        return documentationComment
    }

    private func getMemberDocumentation(_ member: Member, classFactoryKind: ClassFactoryKind? = nil, classDefinition: ClassDefinition? = nil) throws -> MemberDocumentation? {
        // Prefer the documentation comment from the class member over the abi member.
        if let classDefinition,
                member.definingType != classDefinition,
                let classMember = try Self.findClassMember(classDefinition: classDefinition, abiMember: member, classFactoryKind: classFactoryKind),
                let documentation = try getMemberDocumentation(classMember) {
            return documentation
        }

        guard let assemblyDocumentation = assembliesToModules[member.assembly]?.documentation else { return nil }
        return try assemblyDocumentation.lookup(member: member)
    }

    private static func findClassMember(classDefinition: ClassDefinition, abiMember: Member, classFactoryKind: ClassFactoryKind? = nil) throws -> Member? {
        switch abiMember {
            case let method as Method:
                switch classFactoryKind {
                    case .activatable:
                        return try classDefinition.findConstructor(arity: method.arity, inherited: false)
                    case .composable:
                        // Ignore the inner and outer parameters
                        // DependencyObject CreateInstance(object baseInterface, out object innerInterface);
                        return try classDefinition.findConstructor(arity: method.arity - 2, inherited: false)
                    default:
                        return try classDefinition.findMethod(name: method.name, arity: method.arity)
                }
            case let field as Field:
                return classDefinition.findField(name: field.name)
            case let property as Property:
                return classDefinition.findProperty(name: property.name)
            case let event as Event:
                return classDefinition.findEvent(name: event.name)
            default:
                return nil
        }
    }

    public func toDocumentationComment(_ documentation: MemberDocumentation) -> SwiftDocumentationComment {
        var swift = SwiftDocumentationComment()
        if let summary = documentation.summary {
            swift.summary = toBlocks(summary)
        }
        for param in documentation.params {
            swift.params.append(SwiftDocumentationComment.Param(name: param.name, description: toSpans(param.description)))
        }
        if let returns = documentation.returns {
            swift.returns = toSpans(returns)
        }
        return swift
    }
}

fileprivate func toBlocks(_ text: DocumentationText) -> [SwiftDocumentationComment.Block] {
    var blocks = [SwiftDocumentationComment.Block]()
    var spanAccumulator = [SwiftDocumentationComment.Span]()

    func appendSpan(_ span: SwiftDocumentationComment.Span) {
        spanAccumulator.append(span)
    }

    func appendBlock(_ block: SwiftDocumentationComment.Block) {
        if !spanAccumulator.isEmpty {
            blocks.append(.paragraph(spanAccumulator))
            spanAccumulator = []
        }
        blocks.append(block)
    }

    for node in text.nodes {
        switch node {
            case .plain(let text):
                appendSpan(.text(text))
            case .paragraph(let body):
                appendBlock(.paragraph(toSpans(body)))
            case .list(_, let items):
                appendBlock(.list(items.map { .init(text: toSpans($0)) }))
            case .example(let body):
                appendBlock(.paragraph(toSpans(body)))
            case .codeSpan(let code):
                appendSpan(.code(code))
            default:
                break // TODO: Support all node types
        }
    }

    if !spanAccumulator.isEmpty {
        blocks.append(.paragraph(spanAccumulator))
        spanAccumulator = []
    }

    return blocks
}

fileprivate func toSpans(_ text: DocumentationText) -> [SwiftDocumentationComment.Span] {
    var spans = [SwiftDocumentationComment.Span]()

    for node in text.nodes {
        switch node {
            case .plain(let text):
                spans.append(.text(text))
            case .paragraph(let body):
                spans.append(contentsOf: toSpans(body))
            case .example(let body):
                spans.append(contentsOf: toSpans(body))
            case .codeSpan(let code):
                spans.append(.code(code))
            default:
                break // TODO: Support all node types
        }
    }

    return spans
}