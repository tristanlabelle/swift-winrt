import CodeWriters

struct TypeProjection {
    /// Indicates how to map between the Swift and ABI representation of values
    enum ABI {
        /// The Swift type is the same as the ABI type
        case identity(abiType: SwiftType)

        /// The type requires projection using the provided projection type
        /// - Parameter type: The type conforming to ABIProjection
        /// - Parameter inert: The projection does not own resources to be released
        case simple(abiType: SwiftType, projectionType: SwiftType, inert: Bool = false)
    }

    let swiftType: SwiftType
    let abi: ABI?

    init(swiftType: SwiftType) {
        self.swiftType = swiftType
        self.abi = nil
    }

    init(swiftType: SwiftType, abiType: SwiftType) {
        self.swiftType = swiftType
        self.abi = .identity(abiType: abiType)
    }

    init(swiftType: SwiftType, abiType: SwiftType, projectionType: SwiftType, inert: Bool = false) {
        self.swiftType = swiftType
        self.abi = .simple(abiType: abiType, projectionType: projectionType, inert: inert)
    }

    init(swiftType: SwiftType, projectionType: SwiftType, inert: Bool = false) {
        guard case .identifierChain(let projectionTypeIdentifierChain) = projectionType else { preconditionFailure()}
        self.swiftType = swiftType
        self.abi = .simple(
            abiType: SwiftType.identifierChain(projectionTypeIdentifierChain.identifiers + [.init("ABIValue")]),
            projectionType: projectionType, inert: inert)
    }
}