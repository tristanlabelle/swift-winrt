import COM_ABI

public enum HResultBinding: PODBinding {
    public typealias SwiftValue = HResult
    public typealias ABIValue = COM_ABI.SWRT_HResult

    public static var abiDefaultValue: ABIValue { 0 /* S_OK */ }
    public static func fromABI(_ value: COM_ABI.SWRT_HResult) -> SwiftValue { HResult(value) }
    public static func toABI(_ value: HResult) -> COM_ABI.SWRT_HResult { value.value }
}