import DotNetMetadata

class SwiftProjection {
    private(set) var modulesByName: [String: Module] = .init()
    private(set) var assembliesToModules: [Assembly: Module] = .init()

    func addModule(_ name: String, baseNamespace: String?) -> Module {
        let module = Module(projection: self, name: name, baseNamespace: baseNamespace)
        modulesByName[name] = module
        return module
    }

    class Module {
        private unowned let projection: SwiftProjection
        let name: String
        let baseNamespace: String?
        private let baseNamespacePrefix: String
        private(set) var typesByShortNamespace: [String: Set<TypeDefinition>] = .init()
        private(set) var references: Set<Reference> = []

        init(projection: SwiftProjection, name: String, baseNamespace: String?) {
            self.projection = projection
            self.name = name
            self.baseNamespace = baseNamespace
            if let baseNamespace {
                baseNamespacePrefix = baseNamespace + "."
            }
            else {
                baseNamespacePrefix = ""
            }
        }

        func getLocalName(_ type: TypeDefinition) -> String {
            var localName = type.fullName
            localName.trimPrefix(baseNamespacePrefix)
            localName.replace(".", with: "_")
            localName.replace("/", with: "_")
            if let genericSuffixStartIndex = localName.firstIndex(of: TypeDefinition.genericParamCountSeparator) {
                localName.removeSubrange(genericSuffixStartIndex...)
            }
            return localName
        }

        func addAssembly(_ assembly: Assembly) {
            projection.assembliesToModules[assembly] = self
        }

        func addType(_ type: TypeDefinition) {
            precondition(projection.assembliesToModules[type.assembly] === self)
            var shortNamespace = type.namespace ?? ""
            shortNamespace.trimPrefix(baseNamespacePrefix)
            if typesByShortNamespace[shortNamespace] == nil {
                typesByShortNamespace[shortNamespace] = .init()
            }
            typesByShortNamespace[shortNamespace]!.insert(type)
        }

        func addReference(_ other: Module) {
            references.insert(Reference(target: other))
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