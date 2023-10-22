import CWinRTCore

/// Projects the native "boolean" type to Swift's Bool type
public enum BooleanProjection: ABIInertProjection {
    public typealias SwiftValue = Bool
    public typealias ABIValue = CWinRTCore.boolean

    public static var abiDefaultValue: ABIValue { 0 }
    public static func toSwift(_ value: CWinRTCore.boolean) -> Bool { value != 0 }
    public static func toABI(_ value: Bool) -> CWinRTCore.boolean { value ? 1 : 0 }
}