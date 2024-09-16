/// Binds a C(++) wchar_t type to its Swift equivalent, a UTF16 code unit. 
public enum WideCharBinding: PODBinding {
    public typealias ABIValue = UInt16
    public typealias SwiftValue = Unicode.UTF16.CodeUnit

    public static var abiDefaultValue: ABIValue { 0 }
    public static func fromABI(_ value: UInt16) -> Unicode.UTF16.CodeUnit { value }
    public static func toABI(_ value: Unicode.UTF16.CodeUnit) -> UInt16 { value }
}