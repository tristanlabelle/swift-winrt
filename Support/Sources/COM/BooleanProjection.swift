import CWinRTCore

/// Projects the native "boolean" type to Swift's Bool type
public enum BooleanProjection: ABIInertProjection {
    public typealias SwiftValue = Bool
    public typealias ABIValue = Swift.UInt8

    public static var abiDefaultValue: Swift.UInt8 { 0 }
    public static func toSwift(_ value: Swift.UInt8) -> Bool { value != 0 }
    public static func toABI(_ value: Bool) -> Swift.UInt8 { value ? 1 : 0 }
}