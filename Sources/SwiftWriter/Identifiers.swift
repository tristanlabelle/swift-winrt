fileprivate let keywords: Set<String> = [
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

public func isKeyword(_ identifier: String) -> Bool {
    guard let firstChar = identifier.first else { return false }
    // Optimize since most keywords start with a lowercase letter
    return firstChar >= "a" && firstChar <= "z"
        ? keywords.contains(identifier)
        : identifier == "Any" || identifier == "Self"
}

public func writeIdentifier(_ identifier: String, to output: inout some TextOutputStream) {
    let mustEscape = isKeyword(identifier)

    if mustEscape { output.write("`") }
    output.write(identifier)
    if mustEscape { output.write("`") }
}