import DotNetMetadata
import WindowsMetadata
import CodeWriters

public enum CAbi {
    public static func mangleName(type: BoundType) throws -> String {
        var result = namespacingPrefix
        try appendMangledName(type: type, to: &result)
        return result
    }

    internal static func getNamespace(_ typeDefinition: TypeDefinition) throws -> String {
        guard let namespace = typeDefinition.namespace else { 
            throw UnexpectedTypeError(typeDefinition.fullName, reason: "WinRT types must have namespaces")
        }
        return namespace
    }

    internal static func toSystemType(_ typeDefinition: TypeDefinition) throws -> WinRTSystemType? {
        let namespace = try getNamespace(typeDefinition)
        guard !namespace.starts(with: "System.") else { throw UnexpectedTypeError(typeDefinition.fullName, reason: "Not a well-known WinRT System type") }
        guard namespace == "System" else { return nil }
        guard let systemType = WinRTSystemType(fromName: typeDefinition.name) else {
            throw UnexpectedTypeError(typeDefinition.fullName, reason: "Not a well-known WinRT System type")
        }
        return systemType
    }

    internal static func getName(integerType: WinRTIntegerType, mangled: Bool) -> String {
        switch integerType {
            case .uint8: return mangled ? "UInt8" : "uint8_t"
            case .int16: return mangled ? "Int16" : "int16_t"
            case .uint16: return mangled ? "UInt16" : "uint16_t"
            case .int32: return mangled ? "Int32" : "int32_t"
            case .uint32: return mangled ? "UInt32" : "uint32_t"
            case .int64: return mangled ? "Int64" : "int64_t"
            case .uint64: return mangled ? "UInt64" : "uint64_t"
        }
    }

    internal static func getName(systemType: WinRTSystemType, mangled: Bool) -> String {
        switch systemType {
            case .boolean: return mangled ? "Bool" : "bool"
            case .integer(let type): return getName(integerType: type, mangled: mangled)
            case .float(double: false): return mangled ? "Float" : "float"
            case .float(double: true): return mangled ? "Double" : "double"
            case .char: return mangled ? "Char" : "char16_t"
            case .object: return mangled ? "Object" : CAbi.iinspectableName
            case .string: return mangled ? "String" : CAbi.hstringName
            case .guid: return mangled ? "Guid" : CAbi.guidName
        }
    }

    private static func appendMangledName(type: BoundType, to result: inout String) throws {
        if let systemType = try toSystemType(type.definition) {
            result += getName(systemType: systemType, mangled: true)
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
            guard case .bound(let genericArg) = genericArg else {
                throw UnexpectedTypeError(genericArg.description, reason: "WinRT generic arguments must be bound types")
            }

            result += "_"
            try appendMangledName(type: genericArg, to: &result)
        }
    }

    public static var namespacingPrefix: String { "ABI_" }
    public static var hresultName: String { namespacingPrefix + "HResult" }
    public static var guidName: String { namespacingPrefix + "Guid" }
    public static var hstringName: String { namespacingPrefix + "HString" }
    public static var iunknownName: String { namespacingPrefix + "IUnknown" }
    public static var iinspectableName: String { namespacingPrefix + "IInspectable" }
    public static var iactivationFactoryName: String { namespacingPrefix + "IActivationFactory" }

    public static var virtualTableSuffix: String { "VTable" }
    public static var virtualTableFieldName: String { "lpVtbl" }
}