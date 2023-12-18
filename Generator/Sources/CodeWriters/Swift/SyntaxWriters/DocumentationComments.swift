
extension SwiftSyntaxWriter {
    internal func writeDocumentationComment(_ documentationComment: SwiftDocumentationComment) {
        if let summary = documentationComment.summary {
            for block in summary { writeDocumentationCommentBlock(block) }
        }

        for param in documentationComment.params {
            output.write("/// - Parameter ")
            output.write(param.name)
            output.write(": ")
            for span in param.description { writeDocumentationCommentSpan(span) }
            output.endLine(groupWithNext: true)
        }

        if let returns = documentationComment.returns {
            output.write("/// - Returns: ")
            for span in returns { writeDocumentationCommentSpan(span) }
            output.endLine(groupWithNext: true)
        }
    }

    fileprivate func writeDocumentationCommentBlock(_ block: SwiftDocumentationComment.Block) {
        switch block {
            case .paragraph(let spans):
                output.write("/// ")
                for span in spans { writeDocumentationCommentSpan(span) }
                output.endLine(groupWithNext: true)
            default:
                return // TODO: Support more block types
        }
    }

    fileprivate func writeDocumentationCommentSpan(_ span: SwiftDocumentationComment.Span) {
        switch span {
            case .text(let string): output.write(string)
            default:
                return // TODO: Support more inline types
        }
    }
}