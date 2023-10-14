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
        public let allowKeyword: Bool
        public let genericArgs: [SwiftType]

        public init(_ name: String, allowKeyword: Bool = false, genericArgs: [SwiftType] = []) {
            self.name = name
            self.allowKeyword = allowKeyword
            self.genericArgs = genericArgs
        }
    }
}

extension SwiftType {
    public static let void = SwiftType.identifier(name: "Void")
    public static let any = SwiftType.identifier(name: "Any", allowKeyword: true)
    public static let anyObject = SwiftType.identifier(name: "AnyObject")
    public static let never = SwiftType.identifier(name: "Never")
    public static let bool = SwiftType.identifier(name: "Bool")
    public static let float = SwiftType.identifier(name: "Float")
    public static let double = SwiftType.identifier(name: "Double")
    public static let string = SwiftType.identifier(name: "String")
    public static let int = SwiftType.identifier(name: "Int")
    public static let uint = SwiftType.identifier(name: "UInt")

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
        allowKeyword: Bool = false,
        genericArgs: [SwiftType] = []) -> SwiftType {

        .identifierChain(
            IdentifierChain(
                protocolModifier: protocolModifier,
                [ Identifier(name, allowKeyword: allowKeyword, genericArgs: genericArgs) ])
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

    public func unwrapOptional() -> SwiftType {
        switch self {
            case let .optional(wrapped, _): return wrapped
            default: return self
        }
    }
}
