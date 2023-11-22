import DotNetMetadata
import WindowsMetadata
import CodeWriters

public enum CAbi {
    public static func mangleName(type: BoundType) throws -> String {
        var result = namespacingPrefix
        try appendMangledName(type: type, to: &result)
        return result
    }

    internal static func getName(systemTypeName: String, mangled: Bool) -> String? {
        switch systemTypeName {
            case "Boolean": return mangled ? "Bool" : "bool"
            case "SByte": return mangled ? "Int8" : "int8_t"
            case "Byte": return mangled ? "UInt8" : "uint8_t"
            case "Int16": return mangled ? "Int16" : "int16_t"
            case "UInt16": return mangled ? "UInt16" : "uint16_t"
            case "Int32": return mangled ? "Int32" : "int32_t"
            case "UInt32": return mangled ? "UInt32" : "uint32_t"
            case "Int64": return mangled ? "Int64" : "int64_t"
            case "UInt64": return mangled ? "UInt64" : "uint64_t"
            case "Single": return mangled ? "Float" : "float"
            case "Double": return mangled ? "Double" : "double"
            case "Char": return mangled ? "Char" : "char16_t"
            case "Object": return mangled ? "Object" : CAbi.iinspectableName
            case "String": return mangled ? "String" : CAbi.hstringName
            case "Guid": return mangled ? "Guid" : CAbi.guidName
            default: return nil
        }
    }

    private static func appendMangledName(type: BoundType, to result: inout String) throws {
        if type.definition.namespace == "System" {
            guard let mangledName = getName(systemTypeName: type.definition.name, mangled: true) else {
                throw WinMDError.unexpectedType
            }

            result += mangledName
            return
        }

        if let namespace = type.definition.namespace {
            result += namespace.replacingOccurrences(of: ".", with: "")
            result += "_"
        }

        // WinRT only supports a fixed set of generic types, none of which are overloaded,
        // so we can drop the generic arity suffix from the name without ambiguity.
        result += type.definition.nameWithoutGenericSuffix
        for genericArg in type.genericArgs {
            guard case .bound(let genericArg) = genericArg else { throw WinMDError.unexpectedType }
            result += "_"
            try appendMangledName(type: genericArg, to: &result)
        }
    }

    public static var namespacingPrefix: String { "SwiftWinRT_" }
    public static var hresultName: String { namespacingPrefix + "HResult" }
    public static var guidName: String { namespacingPrefix + "Guid" }
    public static var hstringName: String { namespacingPrefix + "HString" }
    public static var iunknownName: String { namespacingPrefix + "IUnknown" }
    public static var iinspectableName: String { namespacingPrefix + "IInspectable" }

    public static var virtualTableSuffix: String { "VTable" }
    public static var virtualTableFieldName: String { "lpVtbl" }
}