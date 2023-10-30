import Collections
import DotNetMetadata

/// Walks the type graph to discovers all type definitions and closed generic types needed by a module.
public struct ModuleTypeDiscoverer {
    private enum QueueEntry {
        case typeDefinition(TypeDefinition)
        case closedGenericType(BoundType)
    }

    private let assemblyFilter: (Assembly) -> Bool
    private let publicMembersOnly: Bool
    private var queue = Deque<QueueEntry>()
    public private(set) var definitions = Set<TypeDefinition>()
    public private(set) var closedGenericTypes = Set<BoundType>()

    public init(assemblyFilter: @escaping (Assembly) -> Bool, publicMembersOnly: Bool = true) {
        self.assemblyFilter = assemblyFilter
        self.publicMembersOnly = publicMembersOnly
    }

    public mutating func add(_ type: TypeDefinition) throws {
        enqueue(type)
        try drainQueue()
    }

    public mutating func add(_ assembly: Assembly, namespace: String? = nil) throws {
        guard assemblyFilter(assembly) else { return }

        for type in assembly.definedTypes {
            guard type.visibility == .public else { continue }
            guard namespace == nil || type.namespace == namespace else { continue }
            enqueue(type)
        }

        try drainQueue()
    }

    private mutating func enqueue(_ typeDefinition: TypeDefinition) {
        guard assemblyFilter(typeDefinition.assembly) else { return }
        guard definitions.insert(typeDefinition).inserted else { return }
        queue.append(.typeDefinition(typeDefinition))
    }

    private mutating func enqueue(_ type: BoundType, genericContext: [TypeNode]?) throws {
        enqueue(type.definition)

        if !type.genericArgs.isEmpty, let genericContext {
            let closedGenericType = type.bindGenericParams(typeArgs: genericContext)
            guard closedGenericTypes.insert(closedGenericType).inserted else { return }
            queue.append(.closedGenericType(closedGenericType))
        }
    }

    private mutating func enqueue(_ type: TypeNode, genericContext: [TypeNode]?) throws {
        switch type {
            case let .bound(bound):
                try enqueue(bound, genericContext: genericContext)
            case let .array(element):
                try enqueue(element, genericContext: genericContext)
            case let .pointer(element):
                if let element { try enqueue(element, genericContext: genericContext) }
            case let .genericParam(genericParam):
                if let genericContext {
                    try enqueue(genericContext[genericParam.index], genericContext: nil)
                }
        }
    }

    private mutating func drainQueue() throws {
        while let entry = queue.popFirst() {
            switch entry {
                case .typeDefinition(let typeDefinition):
                    try enqueueMembers(typeDefinition, genericContext: typeDefinition.genericArity == 0 ? [] : nil)

                case .closedGenericType(let closedGenericType):
                    try enqueueMembers(closedGenericType.definition, genericContext: closedGenericType.genericArgs)
                    for genericArg in closedGenericType.genericArgs {
                        try enqueue(genericArg, genericContext: [])
                    }
            }
        }
    }

    private mutating func enqueueMembers(_ type: TypeDefinition, genericContext: [TypeNode]?) throws {
        if let base = try type.base {
            try enqueue(base, genericContext: genericContext)
        }

        for baseInterface in type.baseInterfaces {
            try enqueue(baseInterface.interface.asBoundType, genericContext: genericContext)
        }

        for field in type.fields {
            guard !publicMembersOnly || field.visibility == .public else { continue }
            try enqueue(field.type, genericContext: genericContext)
        }

        for property in type.properties {
            guard try !publicMembersOnly || property.getter?.visibility == .public else { continue }
            try enqueue(property.type, genericContext: genericContext)
        }

        for event in type.events {
            guard try !publicMembersOnly || event.addAccessor?.visibility == .public else { continue }
            try enqueue(event.handlerType.asBoundType, genericContext: genericContext)
        }

        for method in type.methods {
            guard !publicMembersOnly || method.visibility == .public else { continue }
            for param in try method.params {
                try enqueue(param.type, genericContext: genericContext)
            }

            try enqueue(method.returnType, genericContext: genericContext)
        }
    }
}