import DotNetMetadata
import WindowsMetadata
import CodeWriters

public enum CAbi {
    public static func mangleName(type: BoundType) throws -> String {
        try WinRTTypeName.from(type: type).midlMangling
    }

    public static var virtualTableSuffix: String { "VTable" }
    public static var virtualTableFieldName: String { "lpVtbl" }
}