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
            self.id = Projection.interfaceID
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
    public var unknownPointer: IUnknownPointer { comInterface.unknownPointer }
    open var anyImplementation: Any { self }

    fileprivate init(later: Void) { comInterface = .uninitialized }

    open func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == IUnknownProjection.interfaceID { return unknownPointer.addingRef() }
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
    open var implementation: Projection.SwiftObject { self as! Projection.SwiftObject }
    public var comPointer: Projection.COMPointer {
        comInterface.unknownPointer.cast(to: Projection.COMInterface.self)
    }

    public init() {
        super.init(later: ())
        comInterface = .init(swiftObject: self, virtualTable: Projection.virtualTablePointer)
    }

    open override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        if id == Projection.interfaceID { return unknownPointer.addingRef() }
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
        if let foreignIdentity, id == IUnknownProjection.interfaceID { return foreignIdentity.unknownPointer.addingRef() }
        return try super._queryInterfacePointer(id)
    }
}