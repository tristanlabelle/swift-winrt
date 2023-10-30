
extension SwiftSyntaxWriter {
    internal func writeDocumentationComment(_ documentationComment: SwiftDocumentationComment) {
        output.writeLine("/**")
        if let summary = documentationComment.summary {
            for block in summary { writeDocCommentBlock(block) }
        }

        for param in documentationComment.parameters {
            output.write("- Parameter ")
            output.write(param.name)
            output.write(": ")
            output.write(param.description)
            output.endLine()
        }

        if let returns = documentationComment.returns {
            output.write("- Returns: ")
            for span in returns { writeDocCommentSpan(span) }
            output.endLine()
        }

        output.writeLine("*/")
    }

    fileprivate func writeDocCommentBlock(_ block: SwiftDocumentationComment.Block) {
        switch block {
            case .paragraph(let spans):
                for span in spans { writeDocCommentSpan(span) }
                output.endLine()
            default:
                return // TODO: Support more block types
        }
    }

    fileprivate func writeDocCommentSpan(_ span: SwiftDocumentationComment.Span) {
        switch span {
            case .text(let string): output.write(string)
            default:
                return // TODO: Support more inline types
        }
    }
}