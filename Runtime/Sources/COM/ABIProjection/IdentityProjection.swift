public enum IdentityProjection<Value>: ABIInertProjection {
    public typealias SwiftValue = Value
    public typealias ABIValue = Value

    public static func toSwift(_ value: Value) -> Value { value }
    public static func toABI(_ value: Value) throws -> Value { value }
}