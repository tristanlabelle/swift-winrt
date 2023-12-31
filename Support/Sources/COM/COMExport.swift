/// Base for classes exported to COM.
open class COMExportBase: IUnknownProtocol {
    /// Declares an implemented COM interface for COMExport-derived classes.
    public struct Implements {
        public let id: COMInterfaceID
        public let queryPointer: (_ identity: COMExportBase) throws -> IUnknownPointer

        public init(id: COMInterfaceID, queryPointer: @escaping (_ identity: COMExportBase) throws -> IUnknownPointer) {
            self.id = id
            self.queryPointer = queryPointer
        }

        public init<Projection: COMTwoWayProjection>(_: Projection.Type) {
            self.id = Projection.id
            self.queryPointer = { identity in
                let export = identity.createSecondaryExport(
                    projection: Projection.self,
                    implementation: identity.anyImplementation as! Projection.SwiftObject)
                return export.unknownPointer.addingRef()
            }
        }
    }

    open class var implements: [Implements] { [] }

    fileprivate var comInterface: COMExportedInterface
    public var unknownPointer: IUnknownPointer { comInterface.pointer }
    open var anyImplementation: Any { self }

    fileprivate init(later: Void) { comInterface = .null }

    open func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == IUnknownProjection.id { return unknownPointer.addingRef() }
        guard let interface = Self.implements.first(where: { $0.id == id }) else {
            throw HResult.Error.noInterface
        }
        return try interface.queryPointer(self)
    }

    /// Creates a COMExport object implementing a secondary COM interface and whose identity is delegated to this object.
    open func createSecondaryExport<Projection: COMTwoWayProjection>(
            projection: Projection.Type,
            implementation: Projection.SwiftObject) -> COMExport<Projection> {
        COMWrappingExport<Projection>(implementation: implementation, foreignIdentity: self)
    }

    private static func getImplementation<Projection: COMProjection>(unwrapped: AnyObject, projection: Projection.Type) -> Projection.SwiftObject? {
        if let implementation = (unwrapped as? Projection.SwiftObject) { return implementation }
        if let comExport = unwrapped as? COMExportBase,
            let implementation = comExport.anyImplementation as? Projection.SwiftObject { return implementation }
        return nil
    }

    public static func getImplementationUnsafe<Projection: COMProjection>(_ this: Projection.COMPointer, projection: Projection.Type) -> Projection.SwiftObject {
        getImplementation(unwrapped: COMExportedInterface.unwrapObjectUnsafe(IUnknownPointer.cast(this)), projection: Projection.self)!
    }

    public static func getImplementation<Projection: COMProjection>(_ this: Projection.COMPointer, projection: Projection.Type) -> Projection.SwiftObject? {
        guard COMExportedInterface.test(IUnknownPointer.cast(this)) else { return nil }
        return getImplementation(unwrapped: COMExportedInterface.unwrapObjectUnsafe(IUnknownPointer.cast(this)), projection: Projection.self)
    }
}

/// Base for classes exported to COM.
open class COMExport<Projection: COMTwoWayProjection>: COMExportBase {
    open var implementation: Projection.SwiftObject { self as! Projection.SwiftObject }
    public var comPointer: Projection.COMPointer {
        comInterface.pointer.withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
    }

    public init() {
        super.init(later: ())
        comInterface = .init(
            swiftObject: self,
            virtualTable: Projection.virtualTablePointer.withMemoryRebound(
                to: IUnknownProjection.COMVirtualTable.self, capacity: 1) { $0 })
    }

    open override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == Projection.id { return unknownPointer.addingRef() }
        return try super._queryInterfacePointer(id)
    }

    public func toCOM() -> Projection.COMPointer {
        unknownPointer.addRef()
        return comPointer
    }
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

    open override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        // Delegate our identity
        if let foreignIdentity, id == IUnknownProjection.id { return foreignIdentity.unknownPointer.addingRef() }
        return try super._queryInterfacePointer(id)
    }
}