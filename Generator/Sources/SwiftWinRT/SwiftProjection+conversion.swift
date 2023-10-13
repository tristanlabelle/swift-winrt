import DotNetMetadata
import CodeWriters

extension SwiftProjection {
    static func toVisibility(_ visibility: DotNetMetadata.Visibility, inheritableClass: Bool = false) -> SwiftVisibility {
        switch visibility {
            case .compilerControlled: return .fileprivate
            case .private: return .private
            case .assembly, .familyAndAssembly: return .internal
            case .familyOrAssembly, .family, .public:
                return inheritableClass ? .open : .public
        }
    }

    // Windows.Foundation.Collections to WindowsFoundationCollections
    static func toCompactNamespace(_ namespace: String) -> String {
        namespace.replacing(".", with: "")
    }

    static func toType(mscorlibType: BoundType, referenceNullability: ReferenceNullability) -> SwiftType? {
        guard mscorlibType.definition.namespace == "System" else { return nil }
        if mscorlibType.genericArgs.isEmpty {
            switch mscorlibType.definition.name {
                case "Int16", "UInt16", "Int32", "UInt32", "Int64", "UInt64", "Double", "String", "Void":
                    return .identifier(name: mscorlibType.definition.name)

                case "Boolean": return .bool
                case "SByte": return .int(bits: 8, signed: true)
                case "Byte": return .int(bits: 8, signed: false)
                case "IntPtr": return .int
                case "UIntPtr": return .uint
                case "Single": return .float
                case "Char": return .identifierChain("UTF16", "CodeUnit")
                case "Guid": return .identifierChain("Foundation", "UUID")
                case "Object": return referenceNullability.applyTo(type: .any)

                default: return nil
            }
        }
        else {
            return nil
        }
    }

    static func tryGetIReferenceType(_ type: BoundType) -> TypeNode? {
        guard type.definition.assembly.name == "Windows",
            type.definition.assembly.version == .all255,
            type.definition.namespace == "Windows.Foundation",
            type.definition.name == "IReference`1",
            type.genericArgs.count == 1 else { return nil }
        return type.genericArgs[0]
    }

    func toType(_ type: TypeNode, referenceNullability: ReferenceNullability = .explicit) throws -> SwiftType {
        switch type {
            case let .bound(type):
                // Remap primitive types
                if type.definition.assembly is Mscorlib,
                    let result = Self.toType(mscorlibType: type, referenceNullability: referenceNullability) {
                    return result
                }
                else if let optionalType = Self.tryGetIReferenceType(type) {
                    return .optional(wrapped: try toType(optionalType, referenceNullability: .none), implicitUnwrap: false)
                }

                let name = try toTypeName(type.definition)
                let genericArgs = try type.genericArgs.map { try toType($0) }
                var result: SwiftType = .identifier(name: name, genericArgs: genericArgs)
                if type.definition.isReferenceType && type.definition.fullName != "System.String" {
                    result = referenceNullability.applyTo(type: result)
                }

                return result

            case let .array(element):
                return referenceNullability.applyTo(type: .array(element: try toType(element)))

            case let .genericParam(param):
                return .identifier(name: param.name)

            default:
                fatalError()
        }
    }

    func toReturnType(_ type: TypeNode) throws -> SwiftType? {
        if case let .bound(type) = type,
            let mscorlib = type.definition.assembly as? Mscorlib,
            type.definition === mscorlib.specialTypes.void {
            return nil
        }
        return try toType(type, referenceNullability: .none)
    }

    func toBaseType(_ type: BoundType?) throws -> SwiftType? {
        guard let type else { return nil }
        if let mscorlib = type.definition.assembly as? Mscorlib,
            type.definition === mscorlib.specialTypes.object {
            return nil
        }

        guard type.definition.visibility == .public else { return nil }
        // Generic arguments do not appear on base types in Swift, but as separate typealiases
        if let interfaceDefinition = type.definition as? InterfaceDefinition {
            return .identifier(name: try toProtocolName(interfaceDefinition))
        }
        else {
            return .identifier(name: try toTypeName(type.definition))
        }
    }

    func toTypeName(_ type: TypeDefinition, namespaced: Bool = true) throws -> String {
        try assembliesToModules[type.assembly]!.getName(type, namespaced: namespaced)
    }

    func toProtocolName(_ type: InterfaceDefinition, namespaced: Bool = true) throws -> String {
        try toTypeName(type, namespaced: namespaced) + "Protocol"
    }

    func toMemberName(_ member: Member) -> String { Casing.pascalToCamel(member.name) }

    func toParameter(_ param: Param) throws -> SwiftParameter {
        .init(label: "_", name: param.name!, `inout`: param.isByRef, type: try toType(param.type))
    }

    func isOverriding(_ constructor: Constructor) throws -> Bool {
        var type = constructor.definingType
        let paramTypes = try constructor.params.map { try $0.type }
        while let baseType = try type.base {
            // We don't generate mscorlib types, so we can't shadow their constructors
            guard !(baseType.definition.assembly is Mscorlib) else { break }

            // Base classes should not be generic, see:
            // https://learn.microsoft.com/en-us/uwp/winrt-cref/winrt-type-system
            // "WinRT supports parameterization of interfaces and delegates."
            assert(baseType.genericArgs.isEmpty)
            if let matchingConstructor = baseType.definition.findMethod(name: Constructor.name, paramTypes: paramTypes),
                Self.toVisibility(matchingConstructor.visibility) == .public {
                return true
            }

            type = baseType.definition
        }

        return false
    }

    func toAbiType(_ type: BoundType) -> SwiftType {
        .identifierChain(abiModuleName, CAbi.mangleName(type: type))
    }

    func toAbiVTableType(_ type: BoundType) -> SwiftType {
        guard type.definition is InterfaceDefinition else { fatalError("\(type) has no VTable") }
        return .identifierChain(abiModuleName, CAbi.mangleName(type: type) + CAbi.interfaceVTableSuffix)
    }

    static func toConstant(_ constant: Constant) -> String {
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