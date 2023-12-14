import CWinRTCore

public struct WideChar: Hashable {
    public var codeUnit: UTF16.CodeUnit
    public init(codeUnit: UTF16.CodeUnit) { self.codeUnit = codeUnit }
}

extension WideChar: ABIInertProjection {
    public typealias SwiftValue = Self
    public typealias ABIValue = CWinRTCore.char16_t

    public static var abiDefaultValue: CWinRTCore.char16_t { 0 }
    public static func toSwift(_ value: CWinRTCore.char16_t) -> Self { Self(codeUnit: value) }
    public static func toABI(_ value: WideChar) -> CWinRTCore.char16_t { value.codeUnit }
}