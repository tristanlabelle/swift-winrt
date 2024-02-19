import CodeWriters
import DotNetMetadata
import DotNetXMLDocs
import WindowsMetadata

extension SwiftProjection {
    public static func toVisibility(_ visibility: DotNetMetadata.Visibility, inheritableClass: Bool = false) -> SwiftVisibility {
        switch visibility {
            case .compilerControlled: return .fileprivate
            case .private: return .private
            case .assembly, .familyAndAssembly: return .internal
            case .familyOrAssembly, .family, .public:
                return inheritableClass ? .open : .public
        }
    }

    // Windows.Foundation.Collections to WindowsFoundationCollections
    public static func toCompactNamespace(_ namespace: String) -> String {
        namespace.replacing(".", with: "")
    }

    public func toBaseProtocol(_ interface: InterfaceDefinition) throws -> SwiftType {
        // Protocols have no generic arguments in base type lists
        .identifier(name: try toProtocolName(interface))
    }

    public func toBaseType(_ type: BoundType?) throws -> SwiftType? {
        guard let type else { return nil }
        guard try type.definition != type.definition.context.coreLibrary.systemObject else { return nil }

        guard type.definition.visibility == .public else { return nil }
        // Generic arguments do not appear on base types in Swift, but as separate typealiases
        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            return try toBaseProtocol(interfaceDefinition)
        }
        else {
            return .identifier(name: try toTypeName(type.definition))
        }
    }

    public func toTypeName(_ typeDefinition: TypeDefinition, namespaced: Bool = true) throws -> String {
        try getModule(typeDefinition.assembly)!.getName(typeDefinition, namespaced: namespaced)
    }

    public func toProtocolName(_ typeDefinition: InterfaceDefinition, namespaced: Bool = true) throws -> String {
        try toTypeName(typeDefinition, namespaced: namespaced) + "Protocol"
    }

    public func toProjectionTypeName(_ typeDefinition: TypeDefinition, namespaced: Bool = true) throws -> String {
        var typeName = try toTypeName(typeDefinition, namespaced: namespaced)
        if typeDefinition is InterfaceDefinition
            || typeDefinition is DelegateDefinition
            || typeDefinition is ClassDefinition {
            // protocols and function pointers cannot serve as the projection class,
            // so an accompanying type provides the ABIProjection conformance.
            typeName += "Projection"
        }
        return typeName
    }

    public static func toProjectionInstantiationTypeName(genericArgs: [TypeNode]) throws -> String {
        var result = ""
        func visit(_ type: TypeNode) throws {
            guard case .bound(let type) = type else { fatalError() }
            if !result.isEmpty { result += "_" }
            result += type.definition.nameWithoutGenericSuffix
            for genericArg in type.genericArgs { try visit(genericArg) }
        }

        for genericArg in genericArgs { try visit(genericArg) }

        return result
    }

    public static func toMemberName(_ member: Member) -> String {
        var name = member.name
        if member is Method, member.nameKind == .special {
            if let prefixEndIndex = name.findPrefixEndIndex("get_")
                    ?? name.findPrefixEndIndex("set_")
                    ?? name.findPrefixEndIndex("put_")
                    ?? name.findPrefixEndIndex("add_")
                    ?? name.findPrefixEndIndex("remove_") {
                name = String(name[prefixEndIndex...])
            }
        }
        return Casing.pascalToCamel(name)
    }

    public static func toInteropMethodName(_ method: Method) throws -> String {
        Casing.pascalToCamel(try method.findAttribute(OverloadAttribute.self) ?? method.name)
    }

    public static func toConstant(_ constant: Constant) -> String {
        switch constant {
            case let .boolean(value): return value ? "true" : "false"
            case let .char(value): return String(UInt16(value))
            case let .int8(value): return String(value)
            case let .int16(value): return String(value)
            case let .int32(value): return String(value)
            case let .int64(value): return String(value)
            case let .uint8(value): return String(value)
            case let .uint16(value): return String(value)
            case let .uint32(value): return String(value)
            case let .uint64(value): return String(value)

            case let .single(value):
                if value == Float.infinity { return "Float.infinity" }
                if value == -Float.infinity { return "-Float.infinity" }
                if value.isNaN { return "Float.nan" }
                return String(describing: value)

            case let .double(value):
                if value == Double.infinity { return "Double.infinity" }
                if value == -Double.infinity { return "-Double.infinity" }
                if value.isNaN { return "Double.nan" }
                return String(describing: value)

            case .null: return "nil"
            default: fatalError("Not implemented")
        }
    }
}