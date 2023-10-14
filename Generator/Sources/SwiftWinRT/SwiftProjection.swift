import DotNetMetadata

class SwiftProjection {
    private(set) var modulesByName: [String: Module] = .init()
    private(set) var assembliesToModules: [Assembly: Module] = .init()
    let abiModuleName: String

    init(abiModuleName: String) {
        self.abiModuleName = abiModuleName
    }

    func addModule(_ name: String) -> Module {
        let module = Module(projection: self, name: name)
        modulesByName[name] = module
        return module
    }

    class Module {
        public unowned let projection: SwiftProjection
        public let name: String
        private(set) var typesByNamespace: [String: Set<TypeDefinition>] = .init()
        private(set) var references: Set<Reference> = []

        // When encountering a generic type with a generic arity suffix,
        // we trim the arity suffix iff it wouldn't cause a name clash.
        private var fullNameToGenericPrefixTrimmabilityCache: [String: Bool] = .init()

        init(projection: SwiftProjection, name: String) {
            self.projection = projection
            self.name = name
        }

        func getName(_ type: TypeDefinition, namespaced: Bool = true) throws -> String {
            // Map: Namespace.TypeName
            // To: Namespace_TypeName
            // Map: Namespace.Subnamespace.TypeName/NestedTypeName
            // To: NamespaceSubnamespace_TypeName_NestedTypeName
            var result: String = ""
            if let enclosingType = try type.enclosingType {
                result += try getName(enclosingType, namespaced: namespaced) + "_"
            }
            else if namespaced {
                result += type.namespace.flatMap { SwiftProjection.toCompactNamespace($0) + "_" } ?? ""
            }

            result += canTrimGenericSuffix(type)
                ? type.nameWithoutGenericSuffix
                : type.name.replacingOccurrences(of: "`", with: "_")

            return result
        }

        func addAssembly(_ assembly: Assembly) {
            projection.assembliesToModules[assembly] = self
        }

        func addType(_ type: TypeDefinition) {
            precondition(projection.assembliesToModules[type.assembly] === self)

            typesByNamespace[Module.getNamespaceOrEmpty(type), default: Set()].insert(type)
            fullNameToGenericPrefixTrimmabilityCache.removeAll(keepingCapacity: true)
        }

        func addReference(_ other: Module) {
            references.insert(Reference(target: other))
        }

        private static func getNamespaceOrEmpty(_ type: TypeDefinition) -> String {
            var namespacedType = type
            while namespacedType.namespace == nil, let enclosingType = try? namespacedType.enclosingType {
                namespacedType = enclosingType
            }
            return namespacedType.namespace ?? ""
        }

        // Whether a given type has a generic arity suffix that can be removed without clashing with other types.
        private func canTrimGenericSuffix(_ type: TypeDefinition) -> Bool {
            func getFullNameWithoutGenericSuffix(_ type: TypeDefinition) -> String {
                let name = type.name
                guard let genericSuffixStartIndex = name.lastIndex(of: TypeDefinition.genericParamCountSeparator)
                else { return type.fullName }

                let genericSuffixLength = name.distance(from: genericSuffixStartIndex, to: name.endIndex)
                return String(type.fullName.dropLast(genericSuffixLength))
            }

            let fullNameWithoutGenericSuffix = getFullNameWithoutGenericSuffix(type)
            guard fullNameWithoutGenericSuffix != type.fullName else { return false }

            if let trimmable = fullNameToGenericPrefixTrimmabilityCache[fullNameWithoutGenericSuffix] {
                return trimmable
            }

            // Check if the name would clash with any other type if we removed the generic suffix
            for otherType in typesByNamespace[Module.getNamespaceOrEmpty(type)] ?? [] {
                if otherType !== type && getFullNameWithoutGenericSuffix(otherType) == fullNameWithoutGenericSuffix {
                    fullNameToGenericPrefixTrimmabilityCache[fullNameWithoutGenericSuffix] = false
                    return false
                }
            }

            fullNameToGenericPrefixTrimmabilityCache[fullNameWithoutGenericSuffix] = true
            return true
        }

        struct Reference: Hashable {
            unowned var target: Module

            func hash(into hasher: inout Hasher) {
                hasher.combine(ObjectIdentifier(target))
            }

            static func == (lhs: Module.Reference, rhs: Module.Reference) -> Bool {
                lhs.target === rhs.target
            }
        }
    }
}