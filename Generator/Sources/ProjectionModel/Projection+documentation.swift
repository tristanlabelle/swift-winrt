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
        // Prefer the documentation comment from the class member over the abi member.
        if let classDefinition,
                member.definingType != classDefinition,
                let classMember = try Self.findClassMember(classDefinition: classDefinition, abiMember: member, classFactoryKind: classFactoryKind),
                let documentationComment = try getDocumentationComment(classMember) {
            return documentationComment
        }

        guard let assemblyDocumentation = assembliesToModules[member.assembly]?.documentation else { return nil }
        return try? assemblyDocumentation.lookup(member: member).map(toDocumentationComment)
    }

    public func getDocumentationComment(_ genericParam: GenericParam, typeDefinition: TypeDefinition) -> SwiftDocumentationComment? {
        guard let assemblyDocumentation = assembliesToModules[genericParam.assembly]?.documentation else { return nil }
        return assemblyDocumentation.lookup(typeDefinition: typeDefinition)?.typeParams
            .first { $0.name == genericParam.name }
            .map { $0.description }
            .map {
                var documentationComment = SwiftDocumentationComment()
                documentationComment.summary = toBlocks($0)
                return documentationComment
            }
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