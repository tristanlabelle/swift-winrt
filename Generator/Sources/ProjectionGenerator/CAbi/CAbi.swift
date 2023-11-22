import DotNetMetadata
import WindowsMetadata
import CodeWriters

public enum CAbi {
    public static func mangleName(type: BoundType) throws -> String {
        try WinRTTypeName.from(type: type).midlMangling
    }

    public static var namespacingPrefix: String { "SwiftWinRT_" }
    public static var hresultName: String { namespacingPrefix + "HResult" }
    public static var guidName: String { namespacingPrefix + "Guid" }
    public static var hstringName: String { namespacingPrefix + "HString" }

    public static var virtualTableSuffix: String { "VTable" }
    public static var virtualTableFieldName: String { "lpVtbl" }
}