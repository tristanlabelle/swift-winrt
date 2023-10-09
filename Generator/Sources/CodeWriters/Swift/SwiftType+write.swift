extension SwiftType: CustomStringConvertible, TextOutputStreamable {
    public var description: String {
        var output = ""
        write(to: &output)
        return output
    }

    public func write(to output: inout some TextOutputStream) {
        switch self {
            case let .identifierChain(chain):
                if chain.protocolModifier == .existential {
                    output.write("any ")
                }
                else if chain.protocolModifier == .opaque {
                    output.write("some ")
                }

                for (index, identifier) in chain.identifiers.enumerated() {
                    if index > 0 { output.write(".") }
                    SwiftIdentifiers.write(identifier.name, allowKeyword: identifier.allowKeyword, to: &output)
                    guard !identifier.genericArgs.isEmpty else { continue }
                    output.write("<")
                    for (index, arg) in identifier.genericArgs.enumerated() {
                        if index > 0 { output.write(", ") }
                        arg.write(to: &output)
                    }
                    output.write(">")
                }

            case let .`optional`(wrapped, forceUnwrap):
                let parenthesized: Bool
                if case let .identifierChain(chain) = wrapped, chain.protocolModifier != nil {
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
        }
    }
}
