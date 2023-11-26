/// Projects a uint8_t type to Swift's Bool type
public enum Bool8Projection: ABIInertProjection {
    public typealias SwiftValue = Bool
    public typealias ABIValue = UInt8

    public static var abiDefaultValue: UInt8 { 0 }
    public static func toSwift(_ value: UInt8) -> Bool { value != 0 }
    public static func toABI(_ value: Bool) -> UInt8 { value ? 1 : 0 }
}