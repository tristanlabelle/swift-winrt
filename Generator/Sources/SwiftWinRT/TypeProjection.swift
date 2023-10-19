import CodeWriters

struct TypeProjection {
    struct ABI {
        var projectionType: SwiftType
        var valueType: SwiftType
        var defaultValue: String
        var identity: Bool = false
        var inert: Bool = false
    }

    /// The type for the Swift representation of values.
    let swiftType: SwiftType

    let abi: ABI?

    private init(swiftType: SwiftType, abi: ABI? = nil) {
        self.swiftType = swiftType
        self.abi = abi
    }

    public init(swiftType: SwiftType, projectionType: SwiftType, abiType: SwiftType? = nil, abiDefaultValue: String? = nil, identity: Bool = false, inert: Bool = false) {
        guard case .identifierChain(let projectionTypeIdentifierChain) = projectionType else { preconditionFailure() }
        self.init(swiftType: swiftType,
            abi: ABI(
                projectionType: projectionType,
                valueType: abiType ?? SwiftType.identifierChain(projectionTypeIdentifierChain.identifiers + [.init("ABIValue")]),
                defaultValue: abiDefaultValue ?? projectionType.description + ".abiDefaultValue",
                identity: identity,
                inert: inert))
    }

    public static func noAbi(swiftType: SwiftType) -> TypeProjection {
        TypeProjection(swiftType: swiftType, abi: nil)
    }

    public static func numeric(swiftType: String, abiType: String) -> TypeProjection {
        TypeProjection(
            swiftType: .identifier(name: swiftType),
            projectionType: .identifier(name: "NumericProjection", genericArgs: [.identifier(name: swiftType)]),
            abiType: .identifier(name: abiType),
            abiDefaultValue: "0",
            identity: true,
            inert: true)
    }
}