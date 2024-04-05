extension SwiftType: CustomStringConvertible, TextOutputStreamable {
    public var description: String {
        var output = ""
        write(to: &output)
        return output
    }

    public func write(to output: inout some TextOutputStream) {
        switch self {
            case let .chain(chain):
                if chain.protocolModifier == .any {
                    output.write("any ")
                }
                else if chain.protocolModifier == .some {
                    output.write("some ")
                }

                for (index, component) in chain.components.enumerated() {
                    if index > 0 { output.write(".") }
                    component.identifier.write(to: &output)
                    guard !component.genericArgs.isEmpty else { continue }
                    output.write("<")
                    for (index, arg) in component.genericArgs.enumerated() {
                        if index > 0 { output.write(", ") }
                        arg.write(to: &output)
                    }
                    output.write(">")
                }

            case let .`optional`(wrapped, forceUnwrap):
                let parenthesized: Bool
                if case let .chain(chain) = wrapped, chain.protocolModifier != nil {
                    output.write("(")
                    parenthesized = true
                }
                else {
                    parenthesized = false
                }
                wrapped.write(to: &output)
                if parenthesized { output.write(")") }
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

            case .self: output.write("Self")
            case .any: output.write("Any")
        }
    }
}
