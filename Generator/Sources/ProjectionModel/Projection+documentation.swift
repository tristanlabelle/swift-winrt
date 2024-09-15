import CodeWriters
import DotNetMetadata
import DotNetXMLDocs

extension Projection {
    public func getDocumentation(_ typeDefinition: TypeDefinition) -> MemberDocumentation? {
        guard let documentation = assembliesToModules[typeDefinition.assembly]?.documentation else { return nil }
        return documentation.members[.type(toDocumentationTypeReference(typeDefinition))]
    }

    public func getDocumentationComment(_ typeDefinition: TypeDefinition) -> SwiftDocumentationComment? {
        getDocumentation(typeDefinition).map { toDocumentationComment($0) }
    }

    public func getDocumentationComment(_ member: Member) throws -> SwiftDocumentationComment? {
        guard let documentation = assembliesToModules[member.definingType.assembly]?.documentation else { return nil }
        let declaringType = toDocumentationTypeReference(member.definingType)

        let memberKey: MemberDocumentationKey
        switch member {
            case let field as Field:
                memberKey = .field(declaringType: declaringType, name: field.name)
            case let event as Event:
                memberKey = .event(declaringType: declaringType, name: event.name)
            case let property as Property:
                guard try (property.getter?.arity ?? 0) == 0 else { return nil }
                memberKey = .property(declaringType: declaringType, name: property.name)
            case let method as Method:
                memberKey = try .method(declaringType: declaringType, name: method.name,
                    params: method.params.map { try .init(type: toDocumentationTypeNode($0.type), isByRef: $0.isByRef) })
            default:
                return nil
        }

        return documentation.members[memberKey].map { toDocumentationComment($0) }
    }

    public func getDocumentationComment(abiMember: Member, classDefinition: ClassDefinition?) throws -> SwiftDocumentationComment? {
        // Prefer the documentation comment from the class member over the abi member.
        if let classDefinition {
            let classMember: Member? = try {
                switch abiMember {
                    case let method as Method:
                        return try classDefinition.findMethod(name: method.name, arity: method.arity)
                    case let field as Field:
                        return classDefinition.findField(name: field.name)
                    case let property as Property:
                        return classDefinition.findProperty(name: property.name)
                    case let event as Event:
                        return classDefinition.findEvent(name: event.name)
                    default:
                        return nil
                }
            }()

            if let classMember, let classMemberDocumentation = try getDocumentationComment(classMember) {
                return classMemberDocumentation
            }
        }

        return try getDocumentationComment(abiMember)
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

    public func toDocumentationComment(_ textNode: DocumentationTextNode) -> SwiftDocumentationComment {
        var swift = SwiftDocumentationComment()
        swift.summary = toBlocks(textNode)
        return swift
    }
}

fileprivate func toDocumentationTypeReference(_ typeDefinition: TypeDefinition, genericArgs: [TypeNode]? = nil) -> DocumentationTypeReference {
    DocumentationTypeReference(
        namespace: typeDefinition.namespace,
        nameWithoutGenericArity: typeDefinition.nameWithoutGenericArity,
        genericity: {
            if let genericArgs = genericArgs {
                return .bound(genericArgs.map(toDocumentationTypeNode))
            }
            else if typeDefinition.genericArity > 0 {
                return .unbound(arity: typeDefinition.genericArity)
            }
            else {
                return .bound([])
            }
        }())
}

fileprivate func toDocumentationTypeNode(_ type: TypeNode) -> DocumentationTypeNode {
    switch type {
        case .bound(let type):
            return .bound(toDocumentationTypeReference(type.definition, genericArgs: type.genericArgs))
        case .array(of: let elementType):
            return .array(of: toDocumentationTypeNode(elementType))
        case .pointer(to: let pointeeType):
            return .pointer(to: toDocumentationTypeNode(pointeeType!)) // TODO: Handle void*
        case .genericParam(let param):
            return .genericParam(index: param.index, kind: param is GenericTypeParam ? .type : .method)
    }
}

fileprivate func toBlocks(_ node: DocumentationTextNode) -> [SwiftDocumentationComment.Block] {
    var blocks = [SwiftDocumentationComment.Block]()
    appendBlocks(node, to: &blocks)
    return blocks
}

fileprivate func toSpans(_ node: DocumentationTextNode) -> [SwiftDocumentationComment.Span] {
    var spans = [SwiftDocumentationComment.Span]()
    appendSpans(node, to: &spans)
    return spans
}

fileprivate func appendSpans(_ node: DocumentationTextNode, to spans: inout [SwiftDocumentationComment.Span]) {
    switch node {
        case .plain(let text):
            spans.append(.text(text))
        case .sequence(let nodes):
            for node in nodes { appendSpans(node, to: &spans) }
        case .codeSpan(let code):
            spans.append(.code(code))
        default:
            break // TODO: Support all node types
    }
}

fileprivate func appendBlocks(_ node: DocumentationTextNode, to blocks: inout [SwiftDocumentationComment.Block]) {
    func appendSpan(_ span: SwiftDocumentationComment.Span) {
        if case .paragraph(let paragraph) = blocks.last {
            blocks[blocks.count - 1] = .paragraph(paragraph + [span])
        }
        else {
            blocks.append(.paragraph([span]))
        }
    }

    switch node {
        case .plain(let text):
            appendSpan(.text(text))
        case .sequence(let nodes):
            for node in nodes { appendBlocks(node, to: &blocks) }
        case .paragraph(let body):
            blocks.append(.paragraph([]))
            appendBlocks(body, to: &blocks)
        case .codeSpan(let code):
            appendSpan(.code(code))
        default:
            break // TODO: Support all node types
    }
}
