import Collections
import DotNetMetadata
import DotNetXMLDocs

public final class Module {
    public unowned let projection: Projection
    public let name: String
    public let abiModuleName: String
    public let flattenNamespaces: Bool
    private var weakReferences: Set<Unowned<Module>> = []

    // OrderedSets are not sorted. Sort it lazily for stable iteration.
    private var lazySortedTypeDefinitions = OrderedSet<TypeDefinition>()
    private var typeDefinitionsSorted = true

    public private(set) var genericInstantiationsByDefinition = [TypeDefinition: [[TypeNode]]]()

    internal init(projection: Projection, name: String, flattenNamespaces: Bool = false) {
        self.projection = projection
        self.name = name
        self.abiModuleName = name + CAbi.moduleSuffix
        self.flattenNamespaces = flattenNamespaces
    }

    public var typeDefinitions: OrderedSet<TypeDefinition> {
        if !typeDefinitionsSorted {
            lazySortedTypeDefinitions.sort { $0.fullName < $1.fullName }
            typeDefinitionsSorted = true
        }
        return lazySortedTypeDefinitions
    }

    public var references: [Module] { weakReferences.map { $0.object } }

    public var isEmpty: Bool { lazySortedTypeDefinitions.isEmpty }

    public func addAssembly(_ assembly: Assembly, documentation: AssemblyDocumentation? = nil) {
        projection.addAssembly(assembly, module: self, documentation: documentation)
    }

    public func hasTypeDefinition(_ type: TypeDefinition) -> Bool {
        lazySortedTypeDefinitions.contains(type)
    }

    public func addTypeDefinition(_ type: TypeDefinition) {
        precondition(projection.getModule(type.assembly) === self)
        lazySortedTypeDefinitions.append(type)
        typeDefinitionsSorted = false
    }

    public func addGenericInstantiation(_ type: BoundType) {
        precondition(!type.genericArgs.isEmpty && !type.isParameterized)
        guard genericInstantiationsByDefinition[type.definition]?.contains(type.genericArgs) != true else { return }
        genericInstantiationsByDefinition[type.definition, default: []].append(type.genericArgs)
    }

    public func addReference(_ other: Module) {
        weakReferences.insert(Unowned(other))
    }

    public func getTypeDefinitionsByCompactNamespace(includeGenericInstantiations: Bool) -> OrderedDictionary<String, [TypeDefinition]> {
        var result = OrderedDictionary<String, [TypeDefinition]>()

        for typeDefinition in typeDefinitions {
            let compactNamespace = Projection.toCompactNamespace(typeDefinition.namespace!)
            result[compactNamespace, default: []].append(typeDefinition)
        }

        for typeDefinition in genericInstantiationsByDefinition.keys {
            guard !typeDefinitions.contains(typeDefinition) else { continue } // Don't add twice
            let compactNamespace = Projection.toCompactNamespace(typeDefinition.namespace!)
            result[compactNamespace, default: []].append(typeDefinition)
        }

        result.sort { $0.key < $1.key }

        return result
    }

    public func getTypeInstantiations(definition: TypeDefinition) -> [BoundType] {
        if definition.genericArity == 0 {
            if lazySortedTypeDefinitions.contains(definition) {
                return [ definition.bindType() ]
            }
            else {
                return []
            }
        }
        else {
            let genericInstantiations = genericInstantiationsByDefinition[definition] ?? []
            return genericInstantiations.map { BoundType(definition, genericArgs: $0) }
        }
    }

    public func getNamespaceModuleName(namespace: String) -> String {
        precondition(!flattenNamespaces)
        return "\(name)_\(Projection.toCompactNamespace(namespace))"
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
            result += typeDefinition.namespace.flatMap { Projection.toCompactNamespace($0) + "_" } ?? ""
        }

        result += typeDefinition.nameWithoutGenericArity

        return result
    }

    private static func getNamespaceOrEmpty(_ type: TypeDefinition) -> String {
        var namespacedType = type
        while namespacedType.namespace == nil, let enclosingType = try? namespacedType.enclosingType {
            namespacedType = enclosingType
        }
        return namespacedType.namespace ?? ""
    }
}