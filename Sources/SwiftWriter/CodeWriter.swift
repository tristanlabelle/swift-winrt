public class CodeWriter {
    private enum LineState {
        case start
        case middle
        case end(smartBlankLine: Bool = false)
    }

    private var output: any TextOutputStream
    private var lineState: LineState = .start
    public let indentToken: String
    public var indentLevel = 0

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = output
        self.indentToken = indent
    }

    public func endLine(smartBlankLine: Bool = false) {
        lineState = .end(smartBlankLine: smartBlankLine)
    }

    public func write(_ str: String, inhibitSmartBlankLine: Bool = false, endLine: Bool = false) {
        if case let .end(smartBlankLine) = lineState {
            if smartBlankLine && !inhibitSmartBlankLine {
                output.write("\n")
            }
            output.write("\n")
            lineState = .start
        }

        if !str.isEmpty {
            if case .start = lineState {
                for _ in 0..<indentLevel {
                    output.write(indentToken)
                }
            }
            lineState = .middle
        }

        output.write(str)

        if endLine {
            self.endLine()
        }
    }

    public func writeLine(_ str: String) {
        write(str, endLine: true)
    }

    public func indented(by levels: Int = 1, _ body: () -> Void) {
        indentLevel += levels
        body()
        indentLevel -= levels
    }

    public func indented(at level: Int, _ body: () -> Void) {
        let previousLevel = indentLevel
        indentLevel += level
        body()
        indentLevel -= previousLevel
    }

    public func writeMultilineBlock(_ str: String = "", smartTrailingBlankLine: Bool = true, body: (CodeWriter) -> Void) {
        write(str)
        writeLine(" {")
        indented {
            body(self)
            if case .end = lineState {}
            else { endLine() }
        }
        write("}", inhibitSmartBlankLine: true)
        endLine(smartBlankLine: smartTrailingBlankLine)
    }
}
