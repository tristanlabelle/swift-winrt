public struct SwiftParam: CustomStringConvertible, TextOutputStreamable {
    public var label: SwiftIdentifier?
    public var name: SwiftIdentifier
    public var `inout`: Bool
    public var escaping: Bool
    public var type: SwiftType
    public var defaultValue: String?

    public init(label: String? = nil, name: String, `inout`: Bool = false, escaping: Bool = false, type: SwiftType, defaultValue: String? = nil) {
        self.label = label.map { SwiftIdentifier($0) }
        self.name = SwiftIdentifier(name)
        self.inout = `inout`
        self.escaping = escaping
        self.type = type
        self.defaultValue = defaultValue
    }

    public var description: String {
        var output = ""
        write(to: &output)
        return output
    }

    public func write(to output: inout some TextOutputStream) {
        if let label {
            label.write(to: &output)
            output.write(" ")
        }

        name.write(to: &output)
        output.write(": ")
        if `inout` { output.write("inout ") }
        if escaping { output.write("@escaping ") }
        type.write(to: &output)
        if let defaultValue {
            output.write(" = ")
            output.write(defaultValue)
        }
    }
}