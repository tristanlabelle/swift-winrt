public enum WideCharProjection: ABIInertProjection {
    public typealias SwiftValue = Unicode.UTF16.CodeUnit
    public typealias ABIValue = UInt16

    public static var abiDefaultValue: ABIValue { 0 }
    public static func toSwift(_ value: UInt16) -> Unicode.UTF16.CodeUnit { value }
    public static func toABI(_ value: Unicode.UTF16.CodeUnit) -> UInt16 { value }
}