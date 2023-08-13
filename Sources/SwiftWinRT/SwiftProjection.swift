import DotNetMetadata

class SwiftProjection {
    private(set) var modulesByName: [String: Module] = .init()
    private(set) var assembliesToModules: [Assembly: Module] = .init()

    func addModule(_ name: String) -> Module {
        let module = Module(projection: self, name: name)
        modulesByName[name] = module
        return module
    }

    class Module {
        private unowned let projection: SwiftProjection
        let name: String
        private(set) var typesByNamespace: [String: Set<TypeDefinition>] = .init()
        private(set) var references: Set<Reference> = []

        init(projection: SwiftProjection, name: String) {
            self.projection = projection
            self.name = name
        }

        func getName(_ type: TypeDefinition, any: Bool = false) -> String {
            precondition(!type.isNested)
            precondition(!any || type is InterfaceDefinition)

            let namespacePrefix = type.namespace.flatMap { $0.replacing(".", with: "") + "_" } ?? ""
            var result = namespacePrefix
            if any { result += "Any" }
            result += type.name
            // TODO: Only remove the generic suffix if it won't cause clashes
            if let genericSuffixStartIndex = result.firstIndex(of: TypeDefinition.genericParamCountSeparator) {
                result.removeSubrange(genericSuffixStartIndex...)
            }
            return result
        }

        func addAssembly(_ assembly: Assembly) {
            projection.assembliesToModules[assembly] = self
        }

        func addType(_ type: TypeDefinition) {
            precondition(projection.assembliesToModules[type.assembly] === self)
            typesByNamespace[type.namespace ?? "", default: Set()].insert(type)
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