public enum SwiftIdentifiers {
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

    public static func isKeyword(_ identifier: String) -> Bool {
        guard let firstChar = identifier.first else { return false }
        // Optimize since most keywords start with a lowercase letter
        return firstChar >= "a" && firstChar <= "z"
            ? keywords.contains(identifier)
            : identifier == "Any" || identifier == "Self"
    }

    public static func write(_ identifier: String, allowKeyword: Bool = false, to output: inout some TextOutputStream) {
        let mustEscape = !allowKeyword && isKeyword(identifier)

        if mustEscape { output.write("`") }
        output.write(identifier)
        if mustEscape { output.write("`") }
    }
}
