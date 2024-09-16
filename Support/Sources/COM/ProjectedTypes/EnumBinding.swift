/// Binding for an enumeration whose ABI representation is an integer,
/// and for which any integer is an allowed value.
public protocol OpenEnumBinding: RawRepresentable, PODBinding 
    where ABIValue == RawValue, SwiftValue == Self, RawValue: FixedWidthInteger & Hashable {

    init(rawValue value: RawValue)
}

extension OpenEnumBinding {
    public static var abiDefaultValue: RawValue { RawValue.zero }
    public static func toSwift(_ value: RawValue) -> Self { Self(rawValue: value) }
    public static func toABI(_ value: Self) -> RawValue { value.rawValue }
}

/// Binding for an enumeration whose ABI representation is an integer,
/// and for which allowed values are limited to a set of defined enumerants.
public protocol ClosedEnumBinding: RawRepresentable, PODBinding 
    where ABIValue == RawValue, SwiftValue == Self, RawValue: FixedWidthInteger & Hashable {
}

extension ClosedEnumBinding {
    public static var abiDefaultValue: RawValue { RawValue.zero }
    public static func toSwift(_ value: RawValue) -> Self { Self(rawValue: value)! }
    public static func toABI(_ value: Self) -> RawValue { value.rawValue }
}
