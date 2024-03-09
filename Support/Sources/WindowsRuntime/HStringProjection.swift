import WindowsRuntime_ABI
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = WindowsRuntime_ABI.SWRT_HString?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: WindowsRuntime_ABI.SWRT_HString?) -> SwiftValue {
        HString.toString(value)
    }

    public static func toABI(_ value: String) throws -> WindowsRuntime_ABI.SWRT_HString? {
        try HString.create(value).detach()
    }

    public static func release(_ value: inout WindowsRuntime_ABI.SWRT_HString?) {
        HString.delete(value)
        value = nil
    }
}