import WindowsRuntime_ABI
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = WindowsRuntime_ABI.SWRT_HString?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: WindowsRuntime_ABI.SWRT_HString?) -> SwiftValue {
        value.toString()
    }

    public static func toABI(_ value: String) throws -> WindowsRuntime_ABI.SWRT_HString? {
        try WindowsRuntime_ABI.SWRT_HString.create(value)
    }

    public static func release(_ value: inout WindowsRuntime_ABI.SWRT_HString?) {
        WindowsRuntime_ABI.SWRT_HString.delete(value)
        value = nil
    }
}