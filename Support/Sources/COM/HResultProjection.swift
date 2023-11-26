import CWinRTCore

public enum HResultProjection: ABIInertProjection {
    public typealias SwiftValue = HResult
    public typealias ABIValue = CWinRTCore.SWRT_HResult

    public static var abiDefaultValue: ABIValue { 0 /* S_OK */ }
    public static func toSwift(_ value: CWinRTCore.SWRT_HResult) -> SwiftValue { HResult(value) }
    public static func toABI(_ value: HResult) -> CWinRTCore.SWRT_HResult { value.value }
}