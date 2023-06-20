public class CodeWriter {
    private enum LineState {
        case start
        case middle
        case end
    }

    private var output: any TextOutputStream
    private let indentToken: String
    private var indentLevel = 0
    private var lineState: LineState = .start

    public init(output: some TextOutputStream, indent: String = "    ") {
        self.output = output
        self.indentToken = indent
    }

    public func endLine() {
        lineState = .end
    }

    public func write(_ str: String, endLine: Bool = false) {
        if lineState == .end {
            output.write("\n")
            lineState = .start
        }

        if !str.isEmpty {
            if lineState == .start {
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
        precondition(lineState != .middle)
        write(str, endLine: true)
    }

    public func writeMultilineBlock(_ str: String = "", body: (CodeWriter) -> Void) {
        write(str)
        write(" {", endLine: true)
        indentLevel += 1
        body(self)
        endLine();
        indentLevel -= 1
        writeLine("}")
    }
}
