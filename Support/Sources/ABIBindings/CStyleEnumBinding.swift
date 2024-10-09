/// Binding for an a type implementing CStyleEnum
public protocol CStyleEnumBinding: CStyleEnum, PODBinding 
    where ABIValue == RawValue, SwiftValue == Self {
}

extension CStyleEnumBinding {
    public static var abiDefaultValue: RawValue { RawValue.zero }
    public static func fromABI(_ value: RawValue) -> Self { Self(rawValue: value) }
    public static func toABI(_ value: Self) -> RawValue { value.rawValue }
}
