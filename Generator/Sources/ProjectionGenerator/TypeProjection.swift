import CodeWriters

struct TypeProjection {
    enum ABIKind: Hashable {
        /// The Swift and ABI representations are the same, and do not own any resources.
        case identity
        /// The ABI representation does not own any resources.
        case inert
        /// The ABI representation owns resources.
        case allocating
        /// The ABI representation is a WinRT array.
        case array
    }

    struct ABI {
        var type: SwiftType
        var projectionType: SwiftType
        var defaultValue: String
        var kind: ABIKind
    }

    /// The type for the Swift representation of values.
    let swiftType: SwiftType

    let abi: ABI?

    private init(swiftType: SwiftType, abi: ABI? = nil) {
        self.swiftType = swiftType
        self.abi = abi
    }

    public init(swiftType: SwiftType, abiType: SwiftType? = nil, projectionType: SwiftType, abiDefaultValue: String? = nil, abiKind: ABIKind = .allocating) {
        guard case .chain(let projectionTypeChain) = projectionType else { preconditionFailure() }
        self.init(swiftType: swiftType,
            abi: ABI(
                type: abiType ?? .chain(projectionTypeChain.appending("ABIValue")),
                projectionType: projectionType,
                defaultValue: abiDefaultValue ?? projectionType.description + ".abiDefaultValue",
                kind: abiKind))
    }

    public static func noAbi(swiftType: SwiftType) -> TypeProjection {
        TypeProjection(swiftType: swiftType, abi: nil)
    }

    public static func numeric(swiftType: SwiftType, abiType: String) -> TypeProjection {
        TypeProjection(
            swiftType: swiftType,
            abiType: .identifier(name: abiType),
            projectionType: .identifier("NumericProjection", genericArgs: [swiftType]),
            abiDefaultValue: "0",
            abiKind: .identity)
    }
}