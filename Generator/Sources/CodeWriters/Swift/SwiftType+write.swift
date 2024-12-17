extension SwiftType: CustomStringConvertible, TextOutputStreamable {
    public var description: String {
        var output = ""
        write(to: &output)
        return output
    }

    private func writeNamed(_ identifier: SwiftIdentifier, genericArgs: [SwiftType], to output: inout some TextOutputStream) {
        identifier.write(to: &output)
        if !genericArgs.isEmpty {
            output.write("<")
            for (index, arg) in genericArgs.enumerated() {
                if index > 0 { output.write(", ") }
                arg.write(to: &output)
            }
            output.write(">")
        }
    }

    private func writeParenthesizingProtocolModifiers(_ type: SwiftType, to output: inout some TextOutputStream) {
        switch type {
            case let .existential(`protocol`), let .opaque(`protocol`):
                output.write("(")
                `protocol`.write(to: &output)
                output.write(")")
            default:
                type.write(to: &output)
        }
    }

    public func write(to output: inout some TextOutputStream) {
        switch self {
            case .self: output.write("Self")
            case .any: output.write("Any")

            case let .named(identifier, genericArgs):
                writeNamed(identifier, genericArgs: genericArgs, to: &output)

            case let .member(of, identifier, genericArgs):
                writeParenthesizingProtocolModifiers(of, to: &output)
                output.write(".")
                writeNamed(identifier, genericArgs: genericArgs, to: &output)

            case let .opaque(`protocol`):
                output.write("some ")
                `protocol`.write(to: &output)

            case let .existential(`protocol`):
                output.write("any ")
                `protocol`.write(to: &output)

            case let .`optional`(wrapped, forceUnwrap):
                writeParenthesizingProtocolModifiers(wrapped, to: &output)
                output.write(forceUnwrap ? "!" : "?")

            case let .tuple(elements):
                output.write("(")
                for (index, element) in elements.enumerated() {
                    if index > 0 { output.write(", ") }
                    element.write(to: &output)
                }
                output.write(")")

            case let .array(element):
                output.write("[")
                element.write(to: &output)
                output.write("]")

            case let .dictionary(key, value):
                output.write("[")
                key.write(to: &output)
                output.write(": ")
                value.write(to: &output)
                output.write("]")

            case let .function(params, `throws`, returnType):
                output.write("(")
                for (index, param) in params.enumerated() {
                    if index > 0 { output.write(", ") }
                    param.write(to: &output)
                }
                output.write(")")
                if `throws` { output.write(" throws") }
                output.write(" -> ")
                returnType.write(to: &output)
        }
    }
}
