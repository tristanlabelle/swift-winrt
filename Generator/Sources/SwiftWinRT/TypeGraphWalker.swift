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

    public mutating func walk(_ type: TypeDefinition) {
        enqueue(type)
        drainQueue()
    }

    public mutating func walk(_ type: BoundType) {
        enqueue(type, genericContext: nil)
        drainQueue()
    }

    public mutating func walk(_ type: TypeNode) {
        enqueue(type, genericContext: nil)
        drainQueue()
    }

    public mutating func walk(_ assembly: Assembly, namespace: String? = nil) {
        for type in assembly.definedTypes {
            guard type.visibility == .public else { continue }
            guard namespace == nil || type.namespace == namespace else { continue }
            enqueue(type)
        }

        drainQueue()
    }

    private mutating func enqueue(_ type: TypeDefinition) {
        guard filter(type) else { return }
        guard definitions.insert(type).inserted else { return }
        memberVisitingQueue.append(.definition(type))
    }

    @discardableResult
    private mutating func enqueue(_ type: BoundType, genericContext: Dictionary<GenericParam, TypeNode>?) -> OpenOrClosed {
        guard !closedGenericTypes.contains(type) else { return .closed }

        enqueue(type.definition)

        var openOrClosed = OpenOrClosed.closed
        for genericArg in type.genericArgs {
            if enqueue(genericArg, genericContext: genericContext) == .open {
                openOrClosed = .open
            }
        }

        if openOrClosed == .closed {
            closedGenericTypes.insert(type)
        }

        return openOrClosed
    }

    @discardableResult
    private mutating func enqueue(_ type: TypeNode, genericContext: Dictionary<GenericParam, TypeNode>?) -> OpenOrClosed {
        switch type {
            case let .bound(bound): return enqueue(bound, genericContext: genericContext)
            case let .array(element): return enqueue(element, genericContext: genericContext)
            case let .pointer(element): return enqueue(element, genericContext: genericContext)
            case let .genericArg(genericParam):
                if let genericContext, let genericArg = genericContext[genericParam] {
                    return enqueue(genericArg, genericContext: genericContext)
                }
                else {
                    return .open
                }
        }
    }

    private mutating func drainQueue() {
        var genericArgs = Dictionary<GenericParam, TypeNode>()
        while let entry = memberVisitingQueue.popFirst() {
            switch entry {
                case let .definition(type):
                    enqueueMembers(type, genericContext: nil)

                case let .closedGenericType(type):
                    for i in 0..<type.genericArgs.count {
                        genericArgs[type.definition.genericParams[i]] = type.genericArgs[i]
                    }
                    enqueueMembers(type.definition, genericContext: genericArgs)
                    genericArgs.removeAll()
            }
        }
    }

    private mutating func enqueueMembers(_ type: TypeDefinition, genericContext: Dictionary<GenericParam, TypeNode>?) {
        if let base = type.base {
            enqueue(base, genericContext: genericContext)
        }

        for baseInterface in type.baseInterfaces {
            enqueue(baseInterface.interface, genericContext: genericContext)
        }

        for field in type.fields {
            guard !publicMembersOnly || field.visibility == .public else { continue }
            guard let type = try? field.type else { continue }
            enqueue(type, genericContext: genericContext)
        }

        for property in type.properties {
            guard !publicMembersOnly || property.visibility == .public else { continue }
            guard let type = try? property.type else { continue }
            enqueue(type, genericContext: genericContext)
        }

        for event in type.events {
            guard !publicMembersOnly || event.visibility == .public else { continue }
            guard let handlerType = try? event.handlerType else { continue }
            enqueue(handlerType, genericContext: genericContext)
        }

        for method in type.methods {
            guard !publicMembersOnly || method.visibility == .public else { continue }
            if let params = try? method.params {
                for param in params {
                    enqueue(param.type, genericContext: genericContext)
                }
            }

            if let returnType = try? method.returnType {
                enqueue(returnType, genericContext: genericContext)
            }
        }
    }
}