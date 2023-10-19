// See https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types
public enum SwiftType {
    /// An identifier chain, such as "Foo.Bar" or "any Foo.Bar<Woof.Meow>".
    case chain(Chain)
    indirect case `optional`(wrapped: SwiftType, implicitUnwrap: Bool = false)
    indirect case tuple(elements: [SwiftType])
    indirect case array(element: SwiftType)
    indirect case dictionary(key: SwiftType, value: SwiftType)
    indirect case function(params: [SwiftType], throws: Bool = false, returnType: SwiftType)
    case `self`
    case any

    public enum ProtocolModifier {
        case existential // any
        case opaque // some
    }

    public struct Chain {
        public let protocolModifier: ProtocolModifier?
        public let components: [ChainComponent]

        public init(protocolModifier: ProtocolModifier? = nil, _ components: [ChainComponent]) {
            precondition(!components.isEmpty)
            self.protocolModifier = protocolModifier
            self.components = components
        }

        public func appending(_ component: ChainComponent) -> Chain {
            Chain(protocolModifier: protocolModifier, components + [component])
        }

        public func appending(_ identifier: String, genericArgs: [SwiftType] = []) -> Chain {
            appending(ChainComponent(identifier, genericArgs: genericArgs))
        }
    }

    public struct ChainComponent {
        public let identifier: SwiftIdentifier
        public let genericArgs: [SwiftType]

        public init(_ identifier: String, genericArgs: [SwiftType] = []) {
            self.identifier = SwiftIdentifier(identifier)
            self.genericArgs = genericArgs
        }
    }
}

extension SwiftType {
    public static let void = SwiftType.identifier("Void")
    public static let anyObject = SwiftType.identifier("AnyObject")
    public static let never = SwiftType.identifier("Never")
    public static let bool = SwiftType.identifier("Bool")
    public static let float = SwiftType.identifier("Float")
    public static let double = SwiftType.identifier("Double")
    public static let string = SwiftType.identifier("String")
    public static let int = SwiftType.identifier("Int")
    public static let uint = SwiftType.identifier("UInt")

    public static func int(bits: Int, signed: Bool) -> SwiftType {
        switch (bits, signed) {
            case (8, true): return SwiftType.identifier("Int8")
            case (8, false): return SwiftType.identifier("UInt8")
            case (16, true): return SwiftType.identifier("Int16")
            case (16, false): return SwiftType.identifier("UInt16")
            case (32, true): return SwiftType.identifier("Int32")
            case (32, false): return SwiftType.identifier("UInt32")
            case (64, true): return SwiftType.identifier("Int64")
            case (64, false): return SwiftType.identifier("UInt64")
            default: preconditionFailure("bits should be one of 8, 16, 32 or 64")
        }
    }

    public static func identifier(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        name: String,
        genericArgs: [SwiftType] = []) -> SwiftType {

        .chain(Chain(protocolModifier: protocolModifier, [ ChainComponent(name, genericArgs: genericArgs) ]))
    }

    public static func identifier(_ name: String, genericArgs: [SwiftType] = []) -> SwiftType {
        identifier(name: name, genericArgs: genericArgs)
    }

    public static func chain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ components: [ChainComponent]) -> SwiftType {

        .chain(Chain(protocolModifier: protocolModifier, components))
    }

    public static func chain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ components: ChainComponent...) -> SwiftType {

        .chain(protocolModifier: protocolModifier, components)
    }

    public static func chain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ identifiers: [String]) -> SwiftType {

        .chain(Chain(protocolModifier: protocolModifier, identifiers.map { ChainComponent($0) }))
    }

    public static func chain(
        protocolModifier: SwiftType.ProtocolModifier? = nil,
        _ identifiers: String...) -> SwiftType {

        .chain(protocolModifier: protocolModifier, identifiers)
    }

    public func unwrapOptional() -> SwiftType {
        switch self {
            case let .optional(wrapped, _): return wrapped
            default: return self
        }
    }
}
