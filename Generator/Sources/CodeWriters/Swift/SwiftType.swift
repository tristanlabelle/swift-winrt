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
    public static let void: SwiftType = .chain("Swift", "Void")
    public static let anyObject: SwiftType = .chain("Swift", "AnyObject")
    public static let never: SwiftType = .chain("Swift", "Never")
    public static let bool: SwiftType = .chain("Swift", "Bool")
    public static let float: SwiftType = .chain("Swift", "Float")
    public static let double: SwiftType = .chain("Swift", "Double")
    public static let string: SwiftType = .chain("Swift", "String")
    public static let int: SwiftType = .chain("Swift", "Int")
    public static let uint: SwiftType = .chain("Swift", "UInt")

    public static func int(bits: Int, signed: Bool = true) -> SwiftType {
        switch (bits, signed) {
            case (8, true): return .chain("Swift", "Int8")
            case (8, false): return .chain("Swift", "UInt8")
            case (16, true): return .chain("Swift", "Int16")
            case (16, false): return .chain("Swift", "UInt16")
            case (32, true): return .chain("Swift", "Int32")
            case (32, false): return .chain("Swift", "UInt32")
            case (64, true): return .chain("Swift", "Int64")
            case (64, false): return .chain("Swift", "UInt64")
            default: preconditionFailure("bits should be one of 8, 16, 32 or 64")
        }
    }

    public static func uint(bits: Int) -> SwiftType { int(bits: bits, signed: false) }

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
