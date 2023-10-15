import CABI

/// Projects the native "boolean" type to Swift's Bool type
public enum BooleanProjection: ABIInertProjection {
    public typealias SwiftValue = Bool
    public typealias ABIValue = CABI.boolean

    public static func toSwift(_ value: CABI.boolean) -> Bool { value != 0 }
    public static func toABI(_ value: Bool) throws -> CABI.boolean { value ? 1 : 0 }
}