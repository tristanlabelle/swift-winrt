import CWinRTCore
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = CWinRTCore.HSTRING?

    public static var abiDefaultValue: ABIValue { nil }
    public static func toSwift(consuming value: CWinRTCore.HSTRING?) -> SwiftValue { CWinRTCore.HSTRING.toStringAndDelete(value) }
    public static func toSwift(copying value: CWinRTCore.HSTRING?) -> SwiftValue { value.toString() }
    public static func toABI(_ value: String) throws -> CWinRTCore.HSTRING? { try CWinRTCore.HSTRING.create(value) }
    public static func release(_ value: CWinRTCore.HSTRING?) { CWinRTCore.HSTRING.delete(value) }
}