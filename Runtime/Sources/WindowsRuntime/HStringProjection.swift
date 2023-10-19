import CABI
import COM

public enum HStringProjection: ABIProjection {
    public typealias SwiftValue = String
    public typealias ABIValue = CABI.HSTRING?

    public static var abiDefaultValue: ABIValue { nil }
    public static func toSwift(consuming value: CABI.HSTRING?) -> SwiftValue { CABI.HSTRING.toStringAndDelete(value) }
    public static func toSwift(copying value: CABI.HSTRING?) -> SwiftValue { value.toString() }
    public static func toABI(_ value: String) throws -> CABI.HSTRING? { try CABI.HSTRING.create(value) }
    public static func release(_ value: CABI.HSTRING?) { CABI.HSTRING.delete(value) }
}