/// Protocol for Swift structs which represent C-style enums:
/// backed by a fixed-width integer, and allowing for arbitrary values.
public protocol CStyleEnum: RawRepresentable, Codable, Hashable, Sendable
        where RawValue: FixedWidthInteger {
    init(rawValue value: RawValue)
}

// Bitwise operators for C-style enums used as bitfields.
extension CStyleEnum where Self: OptionSet {
    public static prefix func~(value: Self) -> Self {
        Self(rawValue: ~value.rawValue)
    }

    public static func|(lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs.rawValue | rhs.rawValue)
    }

    public static func&(lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs.rawValue & rhs.rawValue)
    }
}