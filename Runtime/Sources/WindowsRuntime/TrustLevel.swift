import CABI
import COM

public struct TrustLevel: Hashable {
    public var value: Int32
    public init(_ value: Int32 = 0) { self.value = value }

    public static let base = Self(0)
    public static let partial = Self(1)
    public static let full = Self(2)
}

extension TrustLevel: EnumProjection {
    public typealias CEnum = CABI.TrustLevel
}