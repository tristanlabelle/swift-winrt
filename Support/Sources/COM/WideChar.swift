import CWinRTCore

public struct WideChar {
    public var codeUnit: UTF16.CodeUnit
    public init(codeUnit: UTF16.CodeUnit) { self.codeUnit = codeUnit }
}

extension WideChar: ABIInertProjection {
    public typealias SwiftValue = Self
    public typealias ABIValue = CWinRTCore.WCHAR

    public static var abiDefaultValue: CWinRTCore.WCHAR { 0 }
    public static func toSwift(_ value: CWinRTCore.WCHAR) -> Self { Self(codeUnit: value) }
    public static func toABI(_ value: WideChar) -> CWinRTCore.WCHAR { value.codeUnit }
}