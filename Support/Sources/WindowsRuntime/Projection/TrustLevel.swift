import WindowsRuntime_ABI
import COM

/// Represents the trust level of an activatable class.
public struct TrustLevel: CStyleEnum {
    public var rawValue: Int32
    public init(rawValue: Int32 = 0) { self.rawValue = rawValue }

    /// The component has access to resources that are not protected.
    public static let base = Self(rawValue: 0)

    /// The component has access to resources requested in the app manifest and approved by the user.
    public static let partial = Self(rawValue: 1)

    /// The component requires the full privileges of the user.
    public static let full = Self(rawValue: 2)
}

extension TrustLevel: CStyleEnumBinding {}