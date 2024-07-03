import Collections
import DotNetMetadata
import WindowsMetadata

/// Walks a WinRT type graph to discover all type definitions and closed generic types.
public struct WinRTTypeDiscoverer {
    private enum QueueEntry {
        case typeDefinition(TypeDefinition)
        case genericInstantiation(BoundType, assembly: Assembly)
    }

    public class AssemblyTypes {
        public fileprivate(set) var definitions = Set<TypeDefinition>()
        public fileprivate(set) var genericInstantiations = Set<BoundType>()
    }

    private var queue = Deque<QueueEntry>()
    public private(set) var typesByAssembly = Dictionary<Assembly, AssemblyTypes>()

    public init() {}

    public mutating func add(_ type: TypeDefinition) throws {
        enqueue(type)
        try drainQueue()
    }

    private func isWinRTAssembly(_ assembly: Assembly) -> Bool {
        // Stop walking the type graph once we cross into mscorlib
        assembly.name != "mscorlib"
    }

    public mutating func add(_ assembly: Assembly, namespace: String? = nil) throws {
        guard isWinRTAssembly(assembly) else { return }

        for typeDefinition in assembly.typeDefinitions {
            guard namespace == nil || typeDefinition.namespace == namespace else { continue }
            enqueue(typeDefinition)
        }

        for exportedType in assembly.exportedTypes {
            guard namespace == nil || exportedType.namespace == namespace else { continue }
            enqueue(try exportedType.definition)
        }

        try drainQueue()
    }

    private mutating func getAssemblyTypes(_ assembly: Assembly) -> AssemblyTypes {
        if let assemblyTypes = typesByAssembly[assembly] { return assemblyTypes }
        let assemblyTypes = AssemblyTypes()
        typesByAssembly[assembly] = assemblyTypes
        return assemblyTypes
    }

    private mutating func enqueue(_ typeDefinition: TypeDefinition) {
        guard isWinRTAssembly(typeDefinition.assembly) else { return }
        let assemblyTypes = getAssemblyTypes(typeDefinition.assembly)
        guard assemblyTypes.definitions.insert(typeDefinition).inserted else { return }
        queue.append(.typeDefinition(typeDefinition))
    }

    private mutating func enqueue(_ type: BoundType, genericContext: [TypeNode]?, owningAssembly: Assembly) throws {
        enqueue(type.definition)

        if !type.genericArgs.isEmpty, let genericContext {
            let closedGenericType = type.bindGenericParams(typeArgs: genericContext)
            let assemblyTypes = getAssemblyTypes(owningAssembly)
            guard assemblyTypes.genericInstantiations.insert(closedGenericType).inserted else { return }
            queue.append(.genericInstantiation(closedGenericType, assembly: owningAssembly))
        }
    }

    private mutating func enqueue(_ type: TypeNode, genericContext: [TypeNode]?, owningAssembly: Assembly) throws {
        switch type {
            case let .bound(bound):
                try enqueue(bound, genericContext: genericContext, owningAssembly: owningAssembly)
            case let .array(element):
                try enqueue(element, genericContext: genericContext, owningAssembly: owningAssembly)
            case let .pointer(element):
                if let element { try enqueue(element, genericContext: genericContext, owningAssembly: owningAssembly) }
            case let .genericParam(genericParam):
                if let genericContext {
                    try enqueue(genericContext[genericParam.index], genericContext: nil, owningAssembly: owningAssembly)
                }
        }
    }

    private mutating func drainQueue() throws {
        while let entry = queue.popFirst() {
            switch entry {
                case .typeDefinition(let typeDefinition):
                    try enqueueMembers(
                        typeDefinition,
                        genericContext: typeDefinition.genericArity == 0 ? [] : nil,
                        owningAssembly: typeDefinition.assembly)

                case let .genericInstantiation(closedGenericType, assembly: instantiatingAssembly):
                    try enqueueMembers(
                        closedGenericType.definition,
                        genericContext: closedGenericType.genericArgs,
                        owningAssembly: instantiatingAssembly)
                    for genericArg in closedGenericType.genericArgs {
                        try enqueue(genericArg, genericContext: [], owningAssembly: instantiatingAssembly)
                    }
            }
        }
    }

    private mutating func enqueueMembers(_ typeDefinition: TypeDefinition, genericContext: [TypeNode]?, owningAssembly: Assembly) throws {
        if let classDefinition = typeDefinition as? ClassDefinition {
            assert(genericContext?.isEmpty == true) // Classes cannot be generic
            if let base = try typeDefinition.base {
                try enqueue(base, genericContext: genericContext, owningAssembly: owningAssembly)
            }

            for activatableAttribute in try classDefinition.getAttributes(ActivatableAttribute.self) {
                guard let activationFactoryInterface = activatableAttribute.factory else { continue }
                enqueue(activationFactoryInterface)
            }

            for composableAttribute in try classDefinition.getAttributes(ComposableAttribute.self) {
                enqueue(composableAttribute.factory)
            }

            for staticAttribute in try classDefinition.getAttributes(StaticAttribute.self) {
                enqueue(staticAttribute.interface)
            }
        }

        for baseInterface in typeDefinition.baseInterfaces {
            try enqueue(baseInterface.interface.asBoundType, genericContext: genericContext, owningAssembly: owningAssembly)
        }

        for field in typeDefinition.fields {
            assert(genericContext?.isEmpty == true) // Structs and enums cannot be generic
            try enqueue(field.type, genericContext: genericContext, owningAssembly: owningAssembly)
        }

        for property in typeDefinition.properties {
            try enqueue(property.type, genericContext: genericContext, owningAssembly: owningAssembly)
        }

        for event in typeDefinition.events {
            try enqueue(event.handlerType.asBoundType, genericContext: genericContext, owningAssembly: owningAssembly)
        }

        for method in typeDefinition.methods {
            for param in try method.params {
                try enqueue(param.type, genericContext: genericContext, owningAssembly: owningAssembly)
            }

            try enqueue(method.returnType, genericContext: genericContext, owningAssembly: owningAssembly)
        }
    }
}