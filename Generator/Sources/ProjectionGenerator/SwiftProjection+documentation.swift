import CodeWriters
import DotNetMetadata
import DotNetXMLDocs

extension SwiftProjection {
    internal func getDocumentationComment(_ typeDefinition: TypeDefinition) -> SwiftDocumentationComment? {
        guard let documentation = assembliesToModules[typeDefinition.assembly]?.documentation else { return nil }
        return documentation.members[.type(fullName: typeDefinition.fullName)].map { toDocumentationComment($0) }
    }

    internal func getDocumentationComment(_ member: Member) throws -> SwiftDocumentationComment? {
        guard let documentation = assembliesToModules[member.definingType.assembly]?.documentation else { return nil }

        let memberKey: MemberDocumentationKey
        switch member {
            case let field as Field:
                memberKey = .field(declaringType: field.definingType.fullName, name: field.name)
            case let event as Event:
                memberKey = .event(declaringType: event.definingType.fullName, name: event.name)
            case let property as Property:
                guard try (property.getter?.arity ?? 0) == 0 else { return nil }
                memberKey = .property(declaringType: property.definingType.fullName, name: property.name)
            case let method as Method:
                memberKey = try .method(declaringType: method.definingType.fullName, name: method.name,
                    params: method.params.map { try .init(type: toParamType($0.type), isByRef: $0.isByRef) })
            default:
                return nil
        }

        return documentation.members[memberKey].map { toDocumentationComment($0) }
    }
}

fileprivate func toParamType(_ type: TypeNode) -> MemberDocumentationKey.ParamType {
    switch type {
        case .bound(let type):
            return .bound(
                fullName: type.definition.fullName,
                genericArgs: type.genericArgs.map { toParamType($0) })
        case .array(of: let elementType):
            return .array(of: toParamType(elementType))
        case .pointer(to: let pointeeType):
            return .pointer(to: toParamType(pointeeType!)) // TODO: Handle void*
        case .genericParam(let param):
            return .genericArg(index: param.index, kind: param is GenericTypeParam ? .type : .method)
    }
}

fileprivate func toDocumentationComment(_ documentation: MemberDocumentation) -> SwiftDocumentationComment {
    var swift = SwiftDocumentationComment()
    if let summary = documentation.summary {
        swift.summary = toBlocks(summary)
    }
    for param in documentation.params {
        swift.parameters.append(SwiftDocumentationComment.Param(name: param.name, description: toSpans(param.description)))
    }
    if let returns = documentation.returns {
        swift.returns = toSpans(returns)
    }
    return swift
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
