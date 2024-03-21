/// Base for classes exported to COM.
open class COMExportBase: IUnknownProtocol {
    /// Declares an implemented COM interface for COMExport-derived classes.
    public struct Implements {
        public let id: COMInterfaceID
        public let query: (_ identity: COMExportBase) throws -> IUnknownReference

        public init(id: COMInterfaceID, query: @escaping (_ identity: COMExportBase) throws -> IUnknownReference) {
            self.id = id
            self.query = query
        }

        public init<Projection: COMTwoWayProjection>(_: Projection.Type) {
            self.id = Projection.interfaceID
            self.query = { identity in
                let export = identity.createSecondaryExport(
                    projection: Projection.self,
                    implementation: identity.anyImplementation as! Projection.SwiftObject)
                return .init(addingRef: export.unknownPointer)
            }
        }
    }

    open class var implements: [Implements] { [] }

    fileprivate var comInterface: COMExportedInterface
    public var unknownPointer: IUnknownPointer { comInterface.unknownPointer }
    open var anyImplementation: Any { self }

    fileprivate init(later: Void) { comInterface = .uninitialized }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        if id == IUnknownProjection.interfaceID { return .init(addingRef: unknownPointer) }
        guard let interface = Self.implements.first(where: { $0.id == id }) else {
            throw HResult.Error.noInterface
        }
        return try interface.query(self)
    }

    /// Creates a COMExport object implementing a secondary COM interface and whose identity is delegated to this object.
    open func createSecondaryExport<Projection: COMTwoWayProjection>(
            projection: Projection.Type,
            implementation: Projection.SwiftObject) -> COMExport<Projection> {
        COMWrappingExport<Projection>(implementation: implementation, foreignIdentity: self)
    }

    private static func getImplementation<Implementation>(unwrapped: AnyObject) -> Implementation? {
        if let implementation = (unwrapped as? Implementation) { return implementation }
        if let comExport = unwrapped as? COMExportBase,
            let implementation = comExport.anyImplementation as? Implementation { return implementation }
        return nil
    }

    public static func getImplementationUnsafe<Interface, Implementation>(_ this: UnsafeMutablePointer<Interface>) -> Implementation {
        getImplementation(unwrapped: COMExportedInterface.unwrapUnsafe(this))!
    }

    public static func getImplementation<Interface, Implementation>(_ this: UnsafeMutablePointer<Interface>) -> Implementation? {
        guard COMExportedInterface.test(this) else { return nil }
        return getImplementation(unwrapped: COMExportedInterface.unwrapUnsafe(this))
    }
}

/// Base for classes exported to COM.
open class COMExport<Projection: COMTwoWayProjection>: COMExportBase {
    open class var implementIAgileObject: Bool { true }

    open var implementation: Projection.SwiftObject { self as! Projection.SwiftObject }
    public var comPointer: Projection.COMPointer {
        comInterface.unknownPointer.cast(to: Projection.COMInterface.self)
    }

    public init() {
        super.init(later: ())
        comInterface = .init(swiftObject: self, virtualTable: Projection.virtualTablePointer)
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID: return .init(addingRef: unknownPointer)
            case IAgileObjectProjection.interfaceID where Self.implementIAgileObject: return .init(addingRef: unknownPointer)
            default: return try super._queryInterface(id)
        }
    }

    public func toCOM() -> COMReference<Projection.COMInterface> { .init(addingRef: comPointer) }
}

/// Exposes an COM interface implemented by a Swift object.
open class COMWrappingExport<Projection: COMTwoWayProjection>: COMExport<Projection> {
    private let _implementation: Projection.SwiftObject
    public let foreignIdentity: COMExportBase?

    public init(implementation: Projection.SwiftObject, foreignIdentity: COMExportBase? = nil) {
        self._implementation = implementation
        self.foreignIdentity = foreignIdentity
        super.init()
    }

    public override var anyImplementation: Any { _implementation }
    public override var implementation: Projection.SwiftObject { _implementation }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        // Delegate our identity
        if let foreignIdentity, id == IUnknownProjection.interfaceID {
            return .init(addingRef: foreignIdentity.unknownPointer)
        }
        return try super._queryInterface(id)
    }
}