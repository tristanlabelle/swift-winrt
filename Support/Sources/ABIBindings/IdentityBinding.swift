/// Binds a Swift type to an identical ABI type.
public protocol IdentityBinding: PODBinding where SwiftValue == ABIValue {}

extension IdentityBinding {
    public static func toABI(_ value: SwiftValue) -> ABIValue { value }
    public static func toSwift(_ value: ABIValue) -> SwiftValue { value }
}