public struct Parameter: CustomStringConvertible, TextOutputStreamable {
    public var label: String?
    public var name: String
    public var `inout`: Bool
    public var type: SwiftType
    public var defaultValue: String?

    public init(label: String? = nil, name: String, `inout`: Bool = false, type: SwiftType, defaultValue: String? = nil) {
        self.label = label
        self.name = name
        self.inout = `inout`
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
            writeIdentifier(label, to: &output)
            output.write(" ")
        }

        writeIdentifier(name, to: &output)
        output.write(": ")
        if `inout` { output.write("inout ") }
        type.write(to: &output)
        if let defaultValue {
            output.write(" = ")
            output.write(defaultValue)
        }
    }
}