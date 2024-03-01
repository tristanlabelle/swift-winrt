import WindowsRuntime_ABI

public enum BStrProjection: ABIProjection {
    public typealias SwiftValue = String?
    public typealias ABIValue = WindowsRuntime_ABI.SWRT_BStr?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: WindowsRuntime_ABI.SWRT_BStr?) -> String? {
        guard let value else { return nil }
        let length = WindowsRuntime_ABI.SWRT_SysStringLen(value)
        return String(utf16CodeUnits: value, count: Int(length))
    }

    public static func toABI(_ value: String?) throws -> WindowsRuntime_ABI.SWRT_BStr? {
        guard let value else { return nil }
        return value.withCString(encodedAs: UTF16.self) { pointer in
            WindowsRuntime_ABI.SWRT_SysAllocString(pointer)
        }
    }

    public static func release(_ value: inout WindowsRuntime_ABI.SWRT_BStr?) {
        // Docs: "If this parameter is NULL, the function simply returns."
        WindowsRuntime_ABI.SWRT_SysFreeString(value)
        value = nil
    }
}