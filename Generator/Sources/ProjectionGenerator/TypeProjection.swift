import CodeWriters

/// Describes a type's Swift and ABI representation, and how to project between the two.
struct TypeProjection {
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
    /// The type for the ABI representation of values, e.g. `UnsafeMutablePointer<SWRT_IFoo>?`.
    public let abiType: SwiftType
    /// The kind of projection to be performed.
    public let kind: Kind
    /// The type implementing the `ABIProjection` protocol, e.g. `IFooProjection`.
    public let projectionType: SwiftType
    /// The default value for the ABI representation, e.g. `nil`.
    public let abiDefaultValue: String

    public init(swiftType: SwiftType, abiType: SwiftType? = nil, kind: Kind, projectionType: SwiftType, abiDefaultValue: String? = nil) {
        guard case .chain(let projectionTypeChain) = projectionType else { preconditionFailure() }

        self.swiftType = swiftType
        self.abiType = abiType ?? .chain(projectionTypeChain.appending("ABIValue"))
        self.kind = kind
        self.projectionType = projectionType
        self.abiDefaultValue = abiDefaultValue ?? projectionType.description + ".abiDefaultValue"
    }

    public static func numeric(swiftType: SwiftType, abiType: SwiftType? = nil) -> TypeProjection {
        TypeProjection(
            swiftType: swiftType,
            abiType: abiType ?? swiftType,
            kind: .identity,
            projectionType: .identifier("NumericProjection", genericArgs: [swiftType]),
            abiDefaultValue: "0")
    }
}