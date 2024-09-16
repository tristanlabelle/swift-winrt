/// Binds a C numeric type to the corresponding Swift numeric type.
public enum NumericBinding<Value: Numeric>: PODBinding {
    public typealias ABIValue = Value
    public typealias SwiftValue = Value

    public static var abiDefaultValue: ABIValue { Value.zero }
    public static func fromABI(_ value: Value) -> Value { value }
    public static func toABI(_ value: Value) -> Value { value }
}