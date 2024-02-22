public enum BoolProjection: ABIInertProjection {
    public typealias SwiftValue = Bool
    public typealias ABIValue = Bool

    public static var abiDefaultValue: Bool { false }
    public static func toSwift(_ value: Bool) -> Bool { value }
    public static func toABI(_ value: Bool) -> Bool { value }
}