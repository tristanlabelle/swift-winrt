import CodeWriters

/// Describes a type's Swift and ABI representation, and how to project between the two.
public struct TypeProjection {
    public enum DefaultValue: ExpressibleByStringLiteral {
        case fromProjectionType // Projection.abiDefaultValue
        case defaultInitializer // .init()
        case expression(String)

        public init(stringLiteral value: String) { self = .expression(value) }
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

    /// The type for the Swift representation of values, e.g. `IFoo`.
    public let swiftType: SwiftType
    /// The default value for the Swift representation, e.g. `nil`.
    public let swiftDefaultValueEnum: DefaultValue
    /// The type for the ABI representation of values, e.g. `UnsafeMutablePointer<SWRT_IFoo>?`.
    public let abiType: SwiftType
    /// The kind of projection to be performed.
    public let kind: Kind
    /// The type implementing the `ABIProjection` protocol, e.g. `IFooProjection`.
    public let projectionType: SwiftType
    /// The default value for the ABI representation, e.g. `nil`.
    public let abiDefaultValueEnum: DefaultValue

    public var swiftDefaultValue: String {
        switch swiftDefaultValueEnum {
            case .fromProjectionType: fatalError()
            case .defaultInitializer: return "\(swiftType)()"
            case .expression(let expression): return expression
        }
    }

    public var abiDefaultValue: String {
        switch abiDefaultValueEnum {
            case .fromProjectionType: return "\(projectionType).abiDefaultValue"
            case .defaultInitializer: return "\(abiType)()"
            case .expression(let expression): return expression
        }
    }

    public init(
            swiftType: SwiftType,
            swiftDefaultValue: DefaultValue,
            projectionType: SwiftType,
            kind: Kind,
            abiType: SwiftType? = nil,
            abiDefaultValue: DefaultValue = .fromProjectionType) {
        guard case .chain(let projectionTypeChain) = projectionType else { preconditionFailure() }

        self.swiftType = swiftType
        self.swiftDefaultValueEnum = swiftDefaultValue
        self.projectionType = projectionType
        self.kind = kind
        self.abiType = abiType ?? .chain(projectionTypeChain.appending("ABIValue"))
        self.abiDefaultValueEnum = abiDefaultValue
    }

    public static func numeric(swiftType: SwiftType, abiType: SwiftType? = nil) -> TypeProjection {
        TypeProjection(
            swiftType: swiftType,
            swiftDefaultValue: "0",
            projectionType: .identifier("NumericProjection", genericArgs: [swiftType]),
            kind: .identity,
            abiType: abiType ?? swiftType,
            abiDefaultValue: "0")
    }
}