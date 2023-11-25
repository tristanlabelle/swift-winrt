import CWinRTCore
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = CWinRTCore.ABI_HString?

    public static var abiDefaultValue: ABIValue { nil }

    public static func toSwift(consuming value: inout CWinRTCore.ABI_HString?) -> SwiftValue {
        let result = CWinRTCore.ABI_HString.toStringAndDelete(value)
        value = nil
        return result
    }

    public static func toSwift(copying value: CWinRTCore.ABI_HString?) -> SwiftValue {
        value.toString()
    }

    public static func toABI(_ value: String) throws -> CWinRTCore.ABI_HString? {
        try CWinRTCore.ABI_HString.create(value)
    }

    public static func release(_ value: inout CWinRTCore.ABI_HString?) {
        CWinRTCore.ABI_HString.delete(value)
        value = nil
    }
}