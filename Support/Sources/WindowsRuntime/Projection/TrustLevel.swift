import WindowsRuntime_ABI
import COM

public struct TrustLevel: Hashable, RawRepresentable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32 = 0) { self.rawValue = rawValue }

    public static let base = Self(rawValue: 0)
    public static let partial = Self(rawValue: 1)
    public static let full = Self(rawValue: 2)
}

extension TrustLevel: COM.OpenEnumBinding {
}