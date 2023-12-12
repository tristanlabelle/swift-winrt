import CWinRTCore
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = CWinRTCore.SWRT_HString?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(_ value: CWinRTCore.SWRT_HString?) -> SwiftValue {
        value.toString()
    }

    public static func toABI(_ value: String) throws -> CWinRTCore.SWRT_HString? {
        try CWinRTCore.SWRT_HString.create(value)
    }

    public static func release(_ value: inout CWinRTCore.SWRT_HString?) {
        CWinRTCore.SWRT_HString.delete(value)
        value = nil
    }
}