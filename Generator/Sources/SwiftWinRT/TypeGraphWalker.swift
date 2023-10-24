import Collections
import DotNetMetadata

/// Walks graph of type nodes and definitions to find leaf items:
/// - Non-generic type definitions
/// - Generic type definitions
/// - Closed generic types (with all type parameters bound)
struct TypeGraphWalker {
    enum OpenOrClosed {
        case open
        case closed
    }

    enum MemberVisitingQueueEntry {
        case definition(TypeDefinition)
        case closedGenericType(BoundType)
    }

    private let filter: (TypeDefinition) -> Bool
    private let publicMembersOnly: Bool
    private var memberVisitingQueue = Deque<MemberVisitingQueueEntry>()
    public private(set) var definitions = Set<TypeDefinition>()
    public private(set) var closedGenericTypes = Set<BoundType>()

    public init(
        filter: @escaping (TypeDefinition) -> Bool = { _ in true },
        publicMembersOnly: Bool = true) {
        self.filter = filter
        self.publicMembersOnly = publicMembersOnly
    }

    public mutating func walk(_ type: TypeDefinition) throws {
        enqueue(type)
        try drainQueue()
    }

    public mutating func walk(_ type: BoundType) throws {
        try enqueue(type, genericContext: nil)
        try drainQueue()
    }

    public mutating func walk(_ type: TypeNode) throws {
        try enqueue(type, genericContext: nil)
        try drainQueue()
    }

    public mutating func walk(_ assembly: Assembly, namespace: String? = nil) throws {
        for type in assembly.definedTypes {
            guard type.visibility == .public else { continue }
            guard namespace == nil || type.namespace == namespace else { continue }
            enqueue(type)
        }

        try drainQueue()
    }

    private mutating func enqueue(_ type: TypeDefinition) {
        guard filter(type) else { return }
        guard definitions.insert(type).inserted else { return }
        memberVisitingQueue.append(.definition(type))
    }

    @discardableResult
    private mutating func enqueue(_ type: BoundType, genericContext: Dictionary<GenericParam, TypeNode>?) throws -> OpenOrClosed {
        guard !closedGenericTypes.contains(type) else { return .closed }

        enqueue(type.definition)

        var openOrClosed = OpenOrClosed.closed
        for genericArg in type.genericArgs {
            if try enqueue(genericArg, genericContext: genericContext) == .open {
                openOrClosed = .open
            }
        }

        if openOrClosed == .closed {
            closedGenericTypes.insert(type)
        }

        return openOrClosed
    }

    @discardableResult
    private mutating func enqueue(_ type: TypeNode, genericContext: Dictionary<GenericParam, TypeNode>?) throws -> OpenOrClosed {
        switch type {
            case let .bound(bound): return try enqueue(bound, genericContext: genericContext)
            case let .array(element): return try enqueue(element, genericContext: genericContext)
            case let .pointer(element):
                if let element { return try enqueue(element, genericContext: genericContext) }
                else { return .closed }
            case let .genericParam(genericParam):
                if let genericContext, let genericArg = genericContext[genericParam] {
                    return try enqueue(genericArg, genericContext: genericContext)
                }
                else {
                    return .open
                }
        }
    }

    private mutating func drainQueue() throws {
        var genericArgs = Dictionary<GenericParam, TypeNode>()
        while let entry = memberVisitingQueue.popFirst() {
            switch entry {
                case let .definition(type):
                    try enqueueMembers(type, genericContext: nil)

                case let .closedGenericType(type):
                    for i in 0..<type.genericArgs.count {
                        genericArgs[type.definition.genericParams[i]] = type.genericArgs[i]
                    }
                    try enqueueMembers(type.definition, genericContext: genericArgs)
                    genericArgs.removeAll()
            }
        }
    }

    private mutating func enqueueMembers(_ type: TypeDefinition, genericContext: Dictionary<GenericParam, TypeNode>?) throws {
        if let base = try type.base {
            try enqueue(base, genericContext: genericContext)
        }

        for baseInterface in type.baseInterfaces {
            try enqueue(baseInterface.interface.asType, genericContext: genericContext)
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
            try enqueue(event.handlerType.asType, genericContext: genericContext)
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