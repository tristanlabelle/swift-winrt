// See https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types
public enum SwiftType {
    case identifierChain(IdentifierChain)
    indirect case `optional`(wrapped: SwiftType, implicitUnwrap: Bool = false)
    indirect case tuple(elements: [SwiftType])
    indirect case array(element: SwiftType)
    indirect case dictionary(key: SwiftType, value: SwiftType)
    indirect case function(params: [SwiftType], throws: Bool = false, returnType: SwiftType)

    public struct IdentifierChain {
        public let protocolModifier: ProtocolModifier?
        public let identifiers: [Identifier]

        public init(protocolModifier: ProtocolModifier? = nil, _ identifiers: [Identifier]) {
            precondition(!identifiers.isEmpty)
            self.protocolModifier = protocolModifier
            self.identifiers = identifiers
        }
    }

    public enum ProtocolModifier {
        case existential // any
        case opaque // some
    }

    public struct Identifier {
        public let name: String
        public let genericArgs: [SwiftType]

        public init(_ name: String, genericArgs: [SwiftType] = []) {
            self.name = name
            self.genericArgs = genericArgs
        }
    }
}

extension SwiftType {
    public static let void = SwiftType.identifier(name: "Void")
    public static let any = SwiftType.identifier(name: "Any")
    public static let never = SwiftType.identifier(name: "Never")
    public static let bool = SwiftType.identifier(name: "Bool")
    public static let float = SwiftType.identifier(name: "Float")
    public static let double = SwiftType.identifier(name: "Double")
    public static let string = SwiftType.identifier(name: "String")

    public static func int(bits: Int, signed: Bool) -> SwiftType {
        switch (bits, signed) {
            case (8, true): return SwiftType.identifier(name: "Int8")
            case (8, false): return SwiftType.identifier(name: "UInt8")
            case (16, true): return SwiftType.identifier(name: "Int16")
            case (16, false): return SwiftType.identifier(name: "UInt16")
            case (32, true): return SwiftType.identifier(name: "Int32")
            case (32, false): return SwiftType.identifier(name: "UInt32")
            case (64, true): return SwiftType.identifier(name: "Int64")
            case (64, false): return SwiftType.identifier(name: "UInt64")
            default: preconditionFailure("bits should be one of 8, 16, 32 or 64")
        }
    }

    public static func identifier(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        name: String,
        genericArgs: [SwiftType] = []) -> SwiftType {

        .identifierChain(
            IdentifierChain(
                protocolModifier: protocolModifier,
                [ Identifier(name, genericArgs: genericArgs) ])
        )
    }

    public static func identifierChain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ identifiers: [Identifier]) -> SwiftType {

        .identifierChain(IdentifierChain(protocolModifier: protocolModifier, identifiers))
    }
    
    public static func identifierChain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ identifiers: String...) -> SwiftType {
        
        .identifierChain(IdentifierChain(protocolModifier: protocolModifier, identifiers.map { Identifier($0) }))
    }
}

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
                    writeIdentifier(identifier.name, to: &output)
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
