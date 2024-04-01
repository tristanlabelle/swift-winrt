import Collections
import DotNetMetadata
import DotNetXMLDocs

extension SwiftProjection {
    public class Module {
        public unowned let projection: SwiftProjection
        public let name: String
        public let flattenNamespaces: Bool
        private var _typeDefinitions = OrderedSet<TypeDefinition>()
        public private(set) var closedGenericTypesByDefinition = [TypeDefinition: [[TypeNode]]]()
        private(set) var weakReferences: Set<Reference> = []

        internal init(projection: SwiftProjection, name: String, flattenNamespaces: Bool = false) {
            self.projection = projection
            self.name = name
            self.flattenNamespaces = flattenNamespaces
        }

        public var typeDefinitions: OrderedSet<TypeDefinition> {
            _typeDefinitions.sort { $0.fullName < $1.fullName }
            return _typeDefinitions
        }

        public var references: [Module] { weakReferences.map { $0.target } }

        public var isEmpty: Bool { _typeDefinitions.isEmpty }

        public func addAssembly(_ assembly: Assembly, documentation: AssemblyDocumentation? = nil) {
            projection.assembliesToModules[assembly] = AssemblyEntry(module: self, documentation: documentation)
        }

        public func hasTypeDefinition(_ type: TypeDefinition) -> Bool {
            _typeDefinitions.contains(type)
        }

        public func addTypeDefinition(_ type: TypeDefinition) {
            precondition(projection.getModule(type.assembly) === self)
            _typeDefinitions.append(type)
        }

        public func addClosedGenericType(_ type: BoundType) {
            precondition(!type.genericArgs.isEmpty && !type.isParameterized)
            closedGenericTypesByDefinition[type.definition, default: []].append(type.genericArgs)
        }

        public func addReference(_ other: Module) {
            weakReferences.insert(Reference(target: other))
        }

        public func getNamespaceModuleName(namespace: String) -> String {
            precondition(!flattenNamespaces)
            return "\(name)_\(SwiftProjection.toCompactNamespace(namespace))"
        }

        internal func getName(_ typeDefinition: TypeDefinition, namespaced: Bool = true) throws -> String {
            // Map: Namespace.TypeName
            // To: Namespace_TypeName
            // Map: Namespace.Subnamespace.TypeName/NestedTypeName
            // To: NamespaceSubnamespace_TypeName_NestedTypeName
            var result: String = ""
            if let enclosingType = try typeDefinition.enclosingType {
                result += try getName(enclosingType, namespaced: namespaced) + "_"
            }
            else if namespaced && !flattenNamespaces {
                result += typeDefinition.namespace.flatMap { SwiftProjection.toCompactNamespace($0) + "_" } ?? ""
            }

            result += typeDefinition.nameWithoutGenericSuffix

            return result
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