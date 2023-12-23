/// Base for classes exported to COM.
open class COMExport<Projection: COMTwoWayProjection>: IUnknownProtocol {
    open class var queriableInterfaces: [COMExportInterface] { [] }

    // Must be a weak reference to avoid a retain cycle.
    // COMExportedObject must strongly reference this object
    // as it provides the implementation of interface methods.
    public private(set) weak var _comObject: COMExportedObject<Projection>?

    public init() {}

    public func _getCOMObject() -> COMExportedObject<Projection> {
        if let _comObject { return _comObject }
        let newComObject = _createCOMObject()
        _comObject = newComObject
        return newComObject
    }

    open func _createCOMObject() -> COMExportedObject<Projection> {
        COMExportedObject<Projection>(
            implementation: self as! Projection.SwiftObject,
            queriableInterfaces: Self.queriableInterfaces)
    }

    public func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        return try _getCOMObject()._queryInterfacePointer(id)
    }
}