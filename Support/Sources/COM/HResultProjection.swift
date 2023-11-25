import CWinRTCore

public enum HResultProjection: ABIInertProjection {
    public typealias SwiftValue = HResult
    public typealias ABIValue = CWinRTCore.ABI_HResult

    public static var abiDefaultValue: ABIValue { 0 /* S_OK */ }
    public static func toSwift(_ value: CWinRTCore.ABI_HResult) -> SwiftValue { HResult(value) }
    public static func toABI(_ value: HResult) -> CWinRTCore.ABI_HResult { value.value }
}