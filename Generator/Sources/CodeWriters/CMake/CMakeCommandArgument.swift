public struct CMakeCommandArgument: ExpressibleByStringLiteral {
    public let value: String
    public let quoted: Bool

    public init(_ value: String, quoted: Bool) {
        self.value = value
        self.quoted = quoted
    }

    public init(autoquote value: String) {
        assert(!value.contains("${"))
        self.init(value, quoted: value.contains(" ") || value.contains(";"))
    }

    public init(stringLiteral value: String) {
        self.init(autoquote: value)
    }

    public func write(to stream: inout some TextOutputStream) {
        if quoted { stream.write("\"") }
        stream.write(value.replacingOccurrences(of: "\\", with: "\\\\"))
        if quoted { stream.write("\"") }
    }

    public static func autoquote(_ value: String) -> CMakeCommandArgument {
        Self(autoquote: value)
    }

    public static func quoted(_ value: String) -> CMakeCommandArgument {
        Self(value, quoted: true)
    }

    public static func unquoted(_ value: String) -> CMakeCommandArgument {
        Self(value, quoted: false)
    }
}