/// Base for classes that implement and provide identity for COM interfaces.
open class COMExport<Projection: COMTwoWayProjection>: IUnknownProtocol {
    open class var implements: [COMImplements] { [] }
    open class var implementIAgileObject: Bool { true }

    private var comEmbedding: COMEmbedding

    public init() {
        comEmbedding = .uninitialized
        comEmbedding.initialize(embedder: self, virtualTable: Projection.virtualTablePointer)
        assert(self is Projection.SwiftObject)
    }

    public var unknownPointer: IUnknownPointer {
        comEmbedding.unknownPointer
    }

    public var comPointer: Projection.COMPointer {
        Projection.COMPointer(OpaquePointer(comEmbedding.unknownPointer))
    }

    public var _implementation: AnyObject { self }

    /// Creates a COMExport object implementing a secondary COM interface and whose identity is delegated to this object.
    open func createSecondaryExport<Secondary: COMTwoWayProjection>(
            projection: Secondary.Type, implementation: Secondary.SwiftObject) -> COMSecondaryExport<Secondary> {
        COMSecondaryExport<Secondary>(implementation: implementation, identity: self)
    }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID, IUnknownProjection.interfaceID,
                    IAgileObjectProjection.interfaceID where Self.implementIAgileObject:
                return .init(addingRef: comEmbedding.unknownPointer)
            default:
                if let interface = Self.implements.first(where: { $0.id == id }) {
                    return interface.createCOM(implementer: self, identity: self)
                }
                throw HResult.Error.noInterface
        }
    }

    public func toCOM() -> COMReference<Projection.COMInterface> { .init(addingRef: comPointer) }
}

/// Declares an implemented COM interface for COMExport-derived classes.
public struct COMImplements {
    public typealias Factory = (_ implementer: AnyObject, _ identity: IUnknown) -> IUnknownReference

    public let id: COMInterfaceID
    private let factory: Factory

    public init(id: COMInterfaceID, factory: @escaping Factory) {
        self.id = id
        self.factory = factory
    }

    public init<Projection: COMTwoWayProjection>(_: Projection.Type) {
        self.id = Projection.interfaceID
        self.factory = { (implementer, identity) in
            let export = COMSecondaryExport<Projection>(
                implementation: implementer as! Projection.SwiftObject,
                identity: identity)
            return .init(addingRef: export.unknownPointer)
        }
    }

    public func createCOM(implementer: AnyObject, identity: IUnknown) -> IUnknownReference {
        factory(implementer, identity)
    }
}

/// A COM-exported object delegating its implementation to a Swift object.
open class COMWrappingExport<Projection: COMTwoWayProjection>: COMEmbedderWithDelegatedImplementation {
    private var comEmbedding: COMEmbedding
    private let implementation: Projection.SwiftObject

    public init(implementation: Projection.SwiftObject) {
        self.comEmbedding = .uninitialized
        self.implementation = implementation
        self.comEmbedding.initialize(embedder: self, virtualTable: Projection.virtualTablePointer)
    }

    public var unknownPointer: IUnknownPointer {
        comEmbedding.unknownPointer
    }

    public var comPointer: Projection.COMPointer {
        Projection.COMPointer(OpaquePointer(comEmbedding.unknownPointer))
    }

    public var delegatedImplementation: AnyObject { implementation as AnyObject }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID: return .init(addingRef: comEmbedding.unknownPointer)
            case IUnknownProjection.interfaceID: return .init(addingRef: comEmbedding.unknownPointer)
            case IAgileObjectProjection.interfaceID: return .init(addingRef: comEmbedding.unknownPointer)
            default: throw HResult.Error.noInterface
        }
    }

    public func toCOM() -> COMReference<Projection.COMInterface> { .init(addingRef: comPointer) }
}

/// A COM-exported object delegating its implementation and identity to other Swift objects.
public final class COMSecondaryExport<Projection: COMTwoWayProjection>: COMEmbedderWithDelegatedImplementation {
    private var comEmbedding: COMEmbedding
    private let implementation: Projection.SwiftObject
    private let identity: IUnknown

    public init(implementation: Projection.SwiftObject, identity: IUnknown) {
        self.comEmbedding = .uninitialized
        self.implementation = implementation
        self.identity = identity
        self.comEmbedding.initialize(embedder: self, virtualTable: Projection.virtualTablePointer)
    }

    public var unknownPointer: IUnknownPointer { comEmbedding.unknownPointer }
    public var delegatedImplementation: AnyObject { implementation as AnyObject }

    public func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID: return .init(addingRef: comEmbedding.unknownPointer)
            default: return try identity._queryInterface(id)
        }
    }
}