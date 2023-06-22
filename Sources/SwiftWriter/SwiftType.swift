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
        public let items: [Identifier]

        public init(protocolModifier: ProtocolModifier? = nil, items: [Identifier]) {
            precondition(!items.isEmpty)
            self.protocolModifier = protocolModifier
            self.items = items
        }
    }

    public enum ProtocolModifier {
        case existential // any
        case opaque // some
    }

    public struct Identifier {
        public let name: String
        public let genericArgs: [SwiftType]

        public init(name: String, genericArgs: [SwiftType] = []) {
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
                items: [ Identifier(name: name, genericArgs: genericArgs) ])
        )
    }
}
