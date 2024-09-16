/// Binds the C(++) bool type to Swift's Bool type.
public enum BoolBinding: PODBinding {
    public typealias ABIValue = CBool
    public typealias SwiftValue = Bool

    public static var abiDefaultValue: CBool { false }
    public static func fromABI(_ value: CBool) -> Bool { value }
    public static func toABI(_ value: Bool) -> CBool { value }
}