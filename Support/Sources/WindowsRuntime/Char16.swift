import COM

/// Represents the WinRT Char16 (aka System.Char) type, a UTF-16 code unit.
/// Supports type-based disambiguation from UInt16 values.
public struct Char16: Hashable {
    public var codeUnit: UTF16.CodeUnit

    public init(_ codeUnit: UTF16.CodeUnit) {
        self.codeUnit = codeUnit
    }
}

public enum Char16Projection: ABIInertProjection {
    public typealias ABIType = UInt16
    public typealias SwiftType = Char16

    public static var abiDefaultValue: UInt16 { 0 }
    public static func toSwift(_ value: UInt16) -> Char16 { Char16(value) }
    public static func toABI(_ value: Char16) -> UInt16 { value.codeUnit }
}