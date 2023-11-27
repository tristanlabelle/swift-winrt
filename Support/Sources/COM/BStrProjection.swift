import CWinRTCore

public enum BStrProjection: ABIProjection {
    public typealias SwiftValue = String?
    public typealias ABIValue = CWinRTCore.SWRT_BStr?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(consuming value: inout CWinRTCore.SWRT_BStr?) -> String? {
        defer { release(&value) }
        return toSwift(copying: value)
    }

    public static func toSwift(copying value: CWinRTCore.SWRT_BStr?) -> String? {
        guard let value else { return nil }
        let length = CWinRTCore.SWRT_SysStringLen(value)
        return String(utf16CodeUnits: value, count: Int(length))
    }

    public static func toABI(_ value: String?) throws -> CWinRTCore.SWRT_BStr? {
        guard let value else { return nil }
        return value.withCString(encodedAs: UTF16.self) { pointer in
            CWinRTCore.SWRT_SysAllocString(pointer)
        }
    }

    public static func release(_ value: inout CWinRTCore.SWRT_BStr?) {
        // Docs: "If this parameter is NULL, the function simply returns."
        CWinRTCore.SWRT_SysFreeString(value)
        value = nil
    }
}