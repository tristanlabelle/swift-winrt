public class CodeOutputStream: TextOutputStream {
    private enum LineState {
        case start
        case middle
        case end(smartTrailingBlankLine: Bool = false)
    }

    private var inner: any TextOutputStream
    private var lineState: LineState = .start
    public let indentToken: String
    public var indentLevel = 0

    public init(inner: some TextOutputStream, indent: String = "    ") {
        self.inner = inner
        self.indentToken = indent
    }

    public func write(_ str: String) {
        write(str, inhibitSmartBlankLine: false)
    }

    public func write(_ str: String, inhibitSmartBlankLine: Bool = false, endLine: Bool, smartTrailingBlankLine: Bool = false) {
        write(str, inhibitSmartBlankLine: inhibitSmartBlankLine)
        if endLine {
            self.endLine(smartTrailingBlankLine: smartTrailingBlankLine)
        }
    }

    private func write(_ fullStr: String, inhibitSmartBlankLine: Bool) {
        let str = Substring(fullStr)
        if let firstLineEnd = str.firstIndex(of: "\n") {
            // Multiline string, write the first line since we've already figured out where it ends
            writeInline(
                firstLineEnd == str.startIndex ? "" : String(fullStr[str.startIndex..<firstLineEnd]),
                inhibitSmartBlankLine: inhibitSmartBlankLine)
            endLine()

            let secondLineStart = str.index(after: firstLineEnd)
            write(str[secondLineStart...], inhibitSmartBlankLine: false)
        }
        else {
            // Inline string, avoid conversion to Substring
            writeInline(fullStr, inhibitSmartBlankLine: inhibitSmartBlankLine)
        }
    }

    private func write(_ str: Substring, inhibitSmartBlankLine: Bool) {
        let lineEnd = str[str.startIndex...].firstIndex(of: "\n") ?? str.endIndex
        writeInline(
            lineEnd == str.startIndex ? "" : String(str[str.startIndex..<lineEnd]),
            inhibitSmartBlankLine: inhibitSmartBlankLine)
        endLine()

        let nextLineStart = str.index(after: lineEnd)
        if nextLineStart != str.endIndex {
            write(str[nextLineStart...], inhibitSmartBlankLine: false)
        }
    }

    // Writes a string known to not contain newlines
    private func writeInline(_ str: String, inhibitSmartBlankLine: Bool = false) {
        if case let .end(smartBlankLine) = lineState {
            if smartBlankLine && !inhibitSmartBlankLine {
                inner.write("\n")
            }
            inner.write("\n")
            lineState = .start
        }

        guard !str.isEmpty else { return }

        if case .start = lineState {
            for _ in 0..<indentLevel {
                inner.write(indentToken)
            }
            lineState = .middle
        }

        inner.write(str)
    }

    public func endLine(smartTrailingBlankLine: Bool = false) {
        lineState = .end(smartTrailingBlankLine: smartTrailingBlankLine)
    }

    public func writeIndentedBlock(
        header: String = "",
        footer: String? = nil,
        smartTrailingBlankLine: Bool = true,
        body: () -> Void) {

        write(header, endLine: true)

        indentLevel += 1
        body()
        if case .end = lineState {}
        else { endLine() }
        indentLevel -= 1

        if let footer {
            write(footer, inhibitSmartBlankLine: true, endLine: true, smartTrailingBlankLine: smartTrailingBlankLine)
        }
    }
}
