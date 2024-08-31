/// Projects a C numeric type into the corresponding Swift numeric type.
public enum NumericProjection<Value: Numeric>: ABIInertProjection {
    public typealias ABIValue = Value
    public typealias SwiftValue = Value

    public static var abiDefaultValue: ABIValue { Value.zero }
    public static func toSwift(_ value: Value) -> Value { value }
    public static func toABI(_ value: Value) -> Value { value }
}