// Projection for an enumeration whose ABI representation is an integer.
public protocol IntegerEnumProjection: RawRepresentable, ABIInertProjection 
    where ABIValue == RawValue, SwiftValue == Self, RawValue: FixedWidthInteger & Hashable {

    init(rawValue value: RawValue)
}

extension IntegerEnumProjection {
    public static var abiDefaultValue: RawValue { RawValue.zero }
    public static func toSwift(_ value: RawValue) -> Self { Self(rawValue: value) }
    public static func toABI(_ value: Self) -> RawValue { value.rawValue }
}
