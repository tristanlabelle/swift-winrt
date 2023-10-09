open class COMExportBase<Projection: COMTwoWayProjection>: IUnknownProtocol {
    open class var queriableInterfaces: [COMExportInterface] { [] }

    // Must be a weak reference to avoid a retain cycle,
    // since the COMExport must strongly reference this object
    // as it provides the implementation of interface methods.
    public private(set) weak var _comExport: COMExport<Projection>?

    public init() {}

    public func _getCOMExport() -> COMExport<Projection> {
        if let _comExport { return _comExport }
        let newComExport = _createCOMExport()
        _comExport = newComExport
        return newComExport
    }

    open func _createCOMExport() -> COMExport<Projection> {
        COMExport<Projection>(
            implementation: self as! Projection.SwiftValue,
            queriableInterfaces: Self.queriableInterfaces)
    }

    public func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        return try _getCOMExport()._queryInterfacePointer(iid)
    }
}