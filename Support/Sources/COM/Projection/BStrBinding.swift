import COM_ABI

/// Binds a C BSTR to a Swift Optional<String>.
/// Null and empty BSTRs are supposed to be treated the same,
/// but they have different representations, which we preserve into Swift.
public enum BStrBinding: ABIBinding {
    public typealias SwiftValue = String?
    public typealias ABIValue = COM_ABI.SWRT_BStr?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: COM_ABI.SWRT_BStr?) -> String? {
        guard let value else { return nil }
        let length = COM_ABI.SWRT_SysStringLen(value)
        return String(utf16CodeUnits: value, count: Int(length))
    }

    public static func toABI(_ value: String?) throws -> COM_ABI.SWRT_BStr? {
        guard let value else { return nil }
        return value.withCString(encodedAs: UTF16.self) { pointer in
            COM_ABI.SWRT_SysAllocString(pointer)
        }
    }

    public static func release(_ value: inout COM_ABI.SWRT_BStr?) {
        // Docs: "If this parameter is NULL, the function simply returns."
        COM_ABI.SWRT_SysFreeString(value)
        value = nil
    }
}