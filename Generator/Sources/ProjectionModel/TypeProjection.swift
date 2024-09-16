import CodeWriters

/// Describes a type's Swift and ABI representation, and how to project between the two.
public struct TypeProjection {
    public enum DefaultValue: ExpressibleByStringLiteral, CustomStringConvertible {
        case defaultInitializer // .init()
        case expression(String)

        public init(stringLiteral value: String) { self = .expression(value) }

        public static var zero: DefaultValue { .expression("0") }
        public static var `false`: DefaultValue { .expression("false") }
        public static var `nil`: DefaultValue { .expression("nil") }
        public static var emptyString: DefaultValue { .expression("\"\"") }

        public var description: String {
            switch self {
                case .defaultInitializer: return ".init()"
                case .expression(let expression): return expression
            }
        }
    }

    public enum Kind: Hashable {
        /// The Swift and ABI representations are the same, and do not own any resources.
        case identity
        /// The ABI representation is distinct and does not own any resources.
        case inert
        /// The ABI representation is distinct and owns resources.
        case allocating
        /// The ABI representation is a WinRT array.
        case array
    }

    /// The type for the ABI representation of values, e.g. `UnsafeMutablePointer<SWRT_IFoo>?`.
    public let abiType: SwiftType
    /// The default value for the ABI representation, e.g. `nil`.
    public let abiDefaultValue: DefaultValue
    /// The type for the Swift representation of values, e.g. `IFoo`.
    public let swiftType: SwiftType
    /// The default value for the Swift representation, e.g. `nil`.
    public let swiftDefaultValue: DefaultValue
    /// The type implementing the `ABIBinding` protocol, e.g. `IFooBinding`.
    public let bindingType: SwiftType
    /// The kind of projection to be performed.
    public let kind: Kind

    public init(
            abiType: SwiftType, abiDefaultValue: DefaultValue,
            swiftType: SwiftType, swiftDefaultValue: DefaultValue,
            bindingType: SwiftType, kind: Kind) {
        self.abiType = abiType
        self.abiDefaultValue = abiDefaultValue
        self.swiftType = swiftType
        self.swiftDefaultValue = swiftDefaultValue
        self.bindingType = bindingType
        self.kind = kind
    }

    public static func numeric(_ type: SwiftType) -> TypeProjection {
        TypeProjection(
            abiType: type,
            abiDefaultValue: "0",
            swiftType: type,
            swiftDefaultValue: "0",
            bindingType: .identifier("NumericBinding", genericArgs: [type]),
            kind: .identity)
    }
}