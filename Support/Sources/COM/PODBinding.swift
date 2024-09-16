/// A type that binds an ABI value to its corresponding Swift value,
/// where the ABI representation requires no resource allocation.
public protocol PODBinding: ABIBinding {
    static func toABI(_ value: SwiftValue) -> ABIValue // No throw version
}

extension PODBinding {
    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue { toSwift(value) }
    public static func release(_ value: inout ABIValue) {}
}