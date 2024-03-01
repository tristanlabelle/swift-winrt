import WindowsRuntime_ABI

public enum HResultProjection: ABIInertProjection {
    public typealias SwiftValue = HResult
    public typealias ABIValue = WindowsRuntime_ABI.SWRT_HResult

    public static var abiDefaultValue: ABIValue { 0 /* S_OK */ }
    public static func toSwift(_ value: WindowsRuntime_ABI.SWRT_HResult) -> SwiftValue { HResult(value) }
    public static func toABI(_ value: HResult) -> WindowsRuntime_ABI.SWRT_HResult { value.value }
}