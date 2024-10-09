/// Protocol for Swift structs which represent C-style enums:
/// backed by a fixed-width integer, and allowing for arbitrary values.
public protocol CStyleEnum: RawRepresentable, Codable, Hashable, Sendable
        where RawValue: FixedWidthInteger {
    init(rawValue value: RawValue)
}
