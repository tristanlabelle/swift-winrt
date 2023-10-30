import DotNetMetadata

public class SwiftProjection {
    public private(set) var modulesByShortName: [String: Module] = .init()
    public private(set) var assembliesToModules: [Assembly: Module] = .init()
    public let abiModuleName: String
    public var referenceReturnNullability: ReferenceNullability { .explicit } 

    public init(abiModuleName: String) {
        self.abiModuleName = abiModuleName
    }

    public func addModule(shortName: String) -> Module {
        let module = Module(projection: self, shortName: shortName)
        modulesByShortName[shortName] = module
        return module
    }

    public class Module {
        public unowned let projection: SwiftProjection
        public let shortName: String
        public private(set) var typeDefinitionsByNamespace: [String: Set<TypeDefinition>] = .init()
        public private(set) var closedGenericTypesByDefinition: [TypeDefinition: [[TypeNode]]] = .init()
        private(set) var references: Set<Reference> = []

        internal init(projection: SwiftProjection, shortName: String) {
            self.projection = projection
            self.shortName = shortName
        }

        var assemblyModuleName: String { shortName + "Assembly" }

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

            result += type.nameWithoutGenericSuffix

            return result
        }

        public func addAssembly(_ assembly: Assembly) {
            projection.assembliesToModules[assembly] = self
        }

        public func hasTypeDefinition(_ type: TypeDefinition) -> Bool {
            typeDefinitionsByNamespace[Module.getNamespaceOrEmpty(type)]?.contains(type) ?? false
        }

        public func addTypeDefinition(_ type: TypeDefinition) {
            precondition(projection.assembliesToModules[type.assembly] === self)
            typeDefinitionsByNamespace[Module.getNamespaceOrEmpty(type), default: Set()].insert(type)
        }

        public func addClosedGenericType(_ type: BoundType) {
            precondition(!type.genericArgs.isEmpty && !type.isParameterized)
            closedGenericTypesByDefinition[type.definition, default: []].append(type.genericArgs)
        }

        public func addReference(_ other: Module) {
            references.insert(Reference(target: other))
        }

        private static func getNamespaceOrEmpty(_ type: TypeDefinition) -> String {
            var namespacedType = type
            while namespacedType.namespace == nil, let enclosingType = try? namespacedType.enclosingType {
                namespacedType = enclosingType
            }
            return namespacedType.namespace ?? ""
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