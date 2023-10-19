public struct SwiftIdentifier: Hashable, ExpressibleByStringLiteral, CustomStringConvertible, TextOutputStreamable {
    fileprivate static let keywords: Set<String> = [
        // Keywords used in declarations:
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func",
        "import", "init", "inout", "internal", "let", "open", "operator", "private",
        "precedencegroup", "protocol", "public", "rethrows", "static", "struct", "subscript", "typealias", "var",
        // Keywords used in statements:
        "break", "case", "catch", "continue", "default", "defer", "do", "else", "fallthrough",
        "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while",
        // Keywords used in expressions and types:
        "Any", "as", "await", "catch", "false", "is", "nil", "rethrows",
        "self", "Self", "super", "throw", "throws", "true", "try"
    ]

    public let name: String

    public init(_ name: String) { self.name = name }
    public init(stringLiteral name: String) { self.name = name }

    public var isKeyword: Bool {
        guard let firstChar = name.first else { return false }
        // Optimize since most keywords start with a lowercase letter
        return firstChar >= "a" && firstChar <= "z"
            ? Self.keywords.contains(name)
            : name == "Any" || name == "Self"
    }

    public var description: String {
        var output = ""
        write(to: &output)
        return output
    }

    public func write(to output: inout some TextOutputStream) {
        let mustEscape = isKeyword

        if mustEscape { output.write("`") }
        output.write(name)
        if mustEscape { output.write("`") }
    }

    public static func isKeyword(_ name: String) -> Bool { SwiftIdentifier(name).isKeyword }
    public static func write(_ name: String, to output: inout some TextOutputStream) {
        SwiftIdentifier(name).write(to: &output)
    }
}
