/// Projects the C(++) bool type to Swift's Bool type.
public enum BoolProjection: ABIInertProjection {
    public typealias ABIValue = CBool
    public typealias SwiftValue = Bool

    public static var abiDefaultValue: CBool { false }
    public static func toSwift(_ value: CBool) -> Bool { value }
    public static func toABI(_ value: Bool) -> CBool { value }
}