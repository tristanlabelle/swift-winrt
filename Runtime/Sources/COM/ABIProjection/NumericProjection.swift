public enum NumericProjection<Value: Numeric>: ABIInertProjection {
    public typealias SwiftValue = Value
    public typealias ABIValue = Value

    public static var abiDefaultValue: ABIValue { Value.zero }
    public static func toSwift(_ value: Value) -> Value { value }
    public static func toABI(_ value: Value) -> Value { value }
}