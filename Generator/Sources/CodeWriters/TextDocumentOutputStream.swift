import struct Foundation.UUID

/// A TextOutputStream implementation with additional functionality
/// for indentation (line prefixes) and vertical grouping of lines.
public class TextDocumentOutputStream: TextOutputStream {
    private enum LineState {
        case unprefixed
        case prefixed
        case end
    }

    // Classifies lines as to automatically insert blank lines
    // between lines of different groups.
    public enum VerticalGrouping {
        case never
        case withDefault
        case withName(String)
        case withGroup(AnonymousVerticalGroup)
    }

    public struct AnonymousVerticalGroup: Equatable {
        fileprivate let id: Int
        fileprivate init(id: Int) { self.id = id }
    }

    public private(set) var inner: any TextOutputStream
    private var lineState: LineState = .unprefixed
    private var lineGrouping: VerticalGrouping? = nil
    private var lastAllocatedGroupID = 0
    public let defaultLinePrefixIncrement: String
    public let lineEnding: String
    public private(set) var linePrefix = "" // Used for indentation

    public init(inner: some TextOutputStream, defaultLinePrefixIncrement: String = "    ", lineEnding: String = "\n") {
        self.inner = inner
        self.defaultLinePrefixIncrement = defaultLinePrefixIncrement
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
            beginLine(grouping: self.lineGrouping ?? .withDefault)
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

    public func allocateVerticalGrouping() -> VerticalGrouping {
        lastAllocatedGroupID += 1
        return .withGroup(AnonymousVerticalGroup(id: lastAllocatedGroupID))
    }

    public func writeFullLine(grouping: VerticalGrouping = .withDefault, _ str: String = "", groupWithNext: Bool = false) {
        beginLine(grouping: grouping)
        write(str, endLine: true)
        if groupWithNext { lineGrouping = nil }
    }

    private func write(_ str: Substring) {
        let lineEnd = str[str.startIndex...].firstIndex(of: "\n") ?? str.endIndex
        writeInline(
            lineEnd == str.startIndex ? "" : String(str[str.startIndex..<lineEnd]))
        endLine()

        if lineEnd != str.endIndex {
            let nextLineStart = str.index(after: lineEnd)
            beginLine(grouping: self.lineGrouping ?? .withDefault)
            write(str[nextLineStart...])
        }
    }

    // Writes a string known to not contain newlines
    private func writeInline(_ str: String) {
        if lineState == .end {
            beginLine(grouping: .withDefault)
        }

        guard !str.isEmpty else { return }

        if lineState == .unprefixed {
            inner.write(linePrefix)
            lineState = .prefixed
        }

        inner.write(str)
    }

    public func beginLine(grouping: VerticalGrouping = .withDefault) {
        if lineState != .unprefixed {
            inner.write(lineEnding)
        }

        if let previousGrouping = self.lineGrouping,
            !Self.shouldGroup(previousGrouping, grouping) {
            inner.write(lineEnding)
        }

        self.lineGrouping = grouping
        lineState = .unprefixed
    }

    private static func shouldGroup(_ lhs: VerticalGrouping, _ rhs: VerticalGrouping) -> Bool {
        switch (lhs, rhs) {
            case (.never, _), (_, .never):
                return false
            case (.withDefault, .withDefault):
                return true
            case let (.withName(lhs), .withName(rhs)):
                return lhs == rhs
            case let (.withGroup(lhs), .withGroup(rhs)):
                return lhs == rhs
            default:
                return false
        }
    }

    public func endLine(groupWithNext: Bool = false) {
        lineState = .end
        if groupWithNext { lineGrouping = nil }
    }

    public func writeLinePrefixedBlock(
            grouping: VerticalGrouping? = nil,
            header: String? = nil,
            prefixIncrement: String? = nil,
            footer: String? = nil,
            endFooterLine: Bool = true,
            body: () throws -> Void) rethrows {

        if let grouping {
            beginLine(grouping: grouping)
        }
        let grouping = grouping ?? self.lineGrouping ?? .withDefault

        if let header {
            write(header, endLine: true)
        }
        else if lineState != .unprefixed {
            endLine()
        }

        // Force the indented body to be grouped with the previous line
        self.lineGrouping = nil

        let originalLinePrefixEndIndex = linePrefix.endIndex
        linePrefix += prefixIncrement ?? defaultLinePrefixIncrement
        try body()
        if case .end = lineState {}
        else { endLine() }
        linePrefix.removeSubrange(originalLinePrefixEndIndex...)

        if let footer {
            // Force the footer to be grouped with the line above
            self.lineGrouping = nil
            write(footer, endLine: endFooterLine)
        }

        self.lineGrouping = grouping
    }
}
