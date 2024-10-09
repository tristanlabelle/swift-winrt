/// Protocol for Swift enums which represent WinRT enums but do not allow arbitrary values.
public protocol ClosedEnum: RawRepresentable, Codable, Hashable, Sendable
    where RawValue: FixedWidthInteger  {}