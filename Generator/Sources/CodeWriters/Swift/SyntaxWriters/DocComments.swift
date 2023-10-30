
extension SwiftSyntaxWriter {
    internal func writeDocComment(_ docComment: SwiftDocComment) {
        output.writeLine("/**")
        if let summary = docComment.summary {
            for block in summary { writeDocCommentBlock(block) }
        }

        for param in docComment.parameters {
            output.write("- Parameter ")
            output.write(param.name)
            output.write(": ")
            output.write(param.description)
            output.endLine()
        }

        if let returns = docComment.returns {
            output.write("- Returns: ")
            for span in returns { writeDocCommentSpan(span) }
            output.endLine()
        }

        output.writeLine("*/")
    }

    fileprivate func writeDocCommentBlock(_ block: SwiftDocComment.Block) {
        switch block {
            case .paragraph(let spans):
                for span in spans { writeDocCommentSpan(span) }
                output.endLine()
            default:
                return // TODO: Support more block types
        }
    }

    fileprivate func writeDocCommentSpan(_ span: SwiftDocComment.Span) {
        switch span {
            case .text(let string): output.write(string)
            default:
                return // TODO: Support more inline types
        }
    }
}