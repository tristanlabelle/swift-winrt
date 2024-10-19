import struct Foundation.UUID

/// A TextOutputStream implementation with additional functionality
/// for prefixing lines (for indendation) and inserting blank lines
/// between logical groups of lines. Used to write code.
public class LineBasedTextOutputStream: TextOutputStream {
    private enum LineState {
        case unprefixed
        case prefixed
        case end
    }

    // Classifies lines as to automatically insert blank lines
    // between lines of different groups.
    public enum LineGroup {
        case none
        case `default`
        case named(String)
        case anonymous(Anonymous)

        public struct Anonymous: Equatable {
            fileprivate let id: Int
            fileprivate init(id: Int) { self.id = id }
        }
    }

    public private(set) var inner: any TextOutputStream
    private var lineState: LineState = .unprefixed
    private var lineGroup: LineGroup? = nil
    private var lastAnonymousLineGroupID = 0
    public let defaultBlockLinePrefix: String
    public let lineEnding: String
    public private(set) var linePrefix = "" // Used for indentation

    public init(inner: some TextOutputStream, defaultBlockLinePrefix: String = "    ", lineEnding: String = "\n") {
        self.inner = inner
        self.defaultBlockLinePrefix = defaultBlockLinePrefix
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
            beginLine(group: self.lineGroup ?? .default)
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

    public func createLineGroup() -> LineGroup {
        lastAnonymousLineGroupID += 1
        return .anonymous(.init(id: lastAnonymousLineGroupID))
    }

    public func writeFullLine(group: LineGroup = .default, _ str: String = "", groupWithNext: Bool = false) {
        beginLine(group: group)
        write(str, endLine: true)
        if groupWithNext { self.lineGroup = nil }
    }

    private func write(_ str: Substring) {
        let lineEnd = str[str.startIndex...].firstIndex(of: "\n") ?? str.endIndex
        writeInline(
            lineEnd == str.startIndex ? "" : String(str[str.startIndex..<lineEnd]))
        endLine()

        if lineEnd != str.endIndex {
            let nextLineStart = str.index(after: lineEnd)
            beginLine(group: self.lineGroup ?? .default)
            write(str[nextLineStart...])
        }
    }

    // Writes a string known to not contain newlines
    private func writeInline(_ str: String) {
        if lineState == .end {
            beginLine(group: .default)
        }

        guard !str.isEmpty else { return }

        if lineState == .unprefixed {
            inner.write(linePrefix)
            lineState = .prefixed
        }

        inner.write(str)
    }

    public func beginLine(group: LineGroup = .default) {
        if lineState != .unprefixed {
            inner.write(lineEnding)
        }

        if let previousGroup = self.lineGroup,
            !Self.keepTogether(previousGroup, group) {
            inner.write(lineEnding)
        }

        self.lineGroup = group
        lineState = .unprefixed
    }

    private static func keepTogether(_ lhs: LineGroup, _ rhs: LineGroup) -> Bool {
        switch (lhs, rhs) {
            case (.none, _), (_, .none):
                return false
            case (.default, .default):
                return true
            case let (.named(lhs), .named(rhs)):
                return lhs == rhs
            case let (.anonymous(lhs), .anonymous(rhs)):
                return lhs == rhs
            default:
                return false
        }
    }

    public func endLine(groupWithNext: Bool = false) {
        lineState = .end
        if groupWithNext { lineGroup = nil }
    }

    public func writeLineBlock(
            group: LineGroup? = nil,
            header: String? = nil,
            prefix: String? = nil,
            footer: String? = nil,
            endFooterLine: Bool = true,
            body: () throws -> Void) rethrows {

        if let group {
            beginLine(group: group)
        }
        let group = group ?? self.lineGroup ?? .default

        if let header {
            write(header, endLine: true)
        }
        else if lineState != .unprefixed {
            endLine()
        }

        // Force the indented body to be grouped with the previous line
        self.lineGroup = nil

        let originalLinePrefixEndIndex = self.linePrefix.endIndex
        self.linePrefix += `prefix` ?? defaultBlockLinePrefix
        try body()
        if case .end = lineState {}
        else { endLine() }
        self.linePrefix.removeSubrange(originalLinePrefixEndIndex...)

        if let footer {
            // Force the footer to be grouped with the line above
            self.lineGroup = nil
            write(footer, endLine: endFooterLine)
        }

        self.lineGroup = group
    }
}
