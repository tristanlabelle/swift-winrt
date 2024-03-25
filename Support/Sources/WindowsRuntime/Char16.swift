/// Represents the WinRT Char16 (aka System.Char) type, a UTF-16 code unit.
/// Supports type-based disambiguation from UInt16 values.
public struct Char16: Hashable {
    public var codeUnit: UTF16.CodeUnit

    public init(_ codeUnit: UTF16.CodeUnit) {
        self.codeUnit = codeUnit
    }
}
