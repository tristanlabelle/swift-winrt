public class IndentedTextOutputStream: TextOutputStream {
    private enum LineState {
        case preIndent
        case postIndent
        case end
    }

    // Classifies lines as to automatically insert blank lines
    // between lines of different groups.
    public enum VerticalGrouping {
        case never
        case `default`
        case with(String)
    }

    public private(set) var inner: any TextOutputStream
    private var lineState: LineState = .preIndent
    private var lineGrouping: VerticalGrouping? = nil
    public let indentToken: String
    public let lineEnding: String
    public private(set) var indentLevel = 0

    public init(inner: some TextOutputStream, indent: String = "    ", lineEnding: String = "\n") {
        self.inner = inner
        self.indentToken = indent
        self.lineEnding = lineEnding
    }

    public func write(_ str: String) {
        let substr = Substring(str)
        if let firstLineEnd = substr.firstIndex(of: "\n") {
            // Multiline string, write the first line since we've already figured out where it ends
            writeInline(
                firstLineEnd == str.startIndex ? "" : String(str[substr.startIndex..<firstLineEnd]))
            endLine()

            let secondLineStart = str.index(after: firstLineEnd)
            beginLine(grouping: self.lineGrouping ?? .default)
            write(str[secondLineStart...])
        }
        else {
            // Inline string, avoid conversion to Substring
            writeInline(str)
        }
    }

    public func write(_ str: String, endLine: Bool) {
        write(str)
        if endLine { self.endLine() }
    }

    public func writeLine(grouping: VerticalGrouping = .default, _ str: String) {
        beginLine(grouping: grouping)
        write(str, endLine: true)
    }

    private func write(_ str: Substring) {
        let lineEnd = str[str.startIndex...].firstIndex(of: "\n") ?? str.endIndex
        writeInline(
            lineEnd == str.startIndex ? "" : String(str[str.startIndex..<lineEnd]))
        endLine()

        let nextLineStart = str.index(after: lineEnd)
        if nextLineStart != str.endIndex {
            beginLine(grouping: self.lineGrouping ?? .default)
            write(str[nextLineStart...])
        }
    }

    // Writes a string known to not contain newlines
    private func writeInline(_ str: String) {
        if lineState == .end {
            beginLine(grouping: .default)
        }

        guard !str.isEmpty else { return }

        if lineState == .preIndent {
            for _ in 0..<indentLevel {
                inner.write(indentToken)
            }
            lineState = .postIndent
        }

        inner.write(str)
    }

    public func beginLine(grouping: VerticalGrouping = .default) {
        if lineState != .preIndent {
            inner.write(lineEnding)
        }

        if let previousGrouping = self.lineGrouping,
            !Self.shouldGroup(previousGrouping, grouping) {
            inner.write(lineEnding)
        }

        self.lineGrouping = grouping
        lineState = .preIndent
    }

    private static func shouldGroup(_ lhs: VerticalGrouping, _ rhs: VerticalGrouping) -> Bool {
        switch (lhs, rhs) {
            case (.never, _), (_, .never):
                return false
            case (.default, .default):
                return true
            case let (.with(lhsStr), .with(rhsStr)):
                return lhsStr == rhsStr
            default:
                return false
        }
    }

    public func endLine() {
        lineState = .end
    }

    public func writeIndentedBlock(
        grouping: VerticalGrouping? = nil,
        header: String? = nil,
        footer: String? = nil,
        body: () -> Void) {

        if let grouping {
            beginLine(grouping: grouping)
        }
        let grouping = grouping ?? self.lineGrouping ?? .default

        if let header {
            write(header, endLine: true)
        }
        else if lineState != .preIndent {
            endLine()
        }

        // Force the indented body to be grouped with the previous line
        self.lineGrouping = nil

        indentLevel += 1
        body()
        if case .end = lineState {}
        else { endLine() }
        indentLevel -= 1

        if let footer {
            // Force the footer to be grouped with the line above
            self.lineGrouping = nil
            write(footer, endLine: true)
            self.lineGrouping = grouping
        }
    }
}
