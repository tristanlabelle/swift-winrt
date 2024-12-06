/// A COM-exported object providing a secondary interface to a primary exported object.
open class COMSecondaryExport<InterfaceBinding: COMTwoWayBinding>: IUnknownProtocol {
    private var implements: COMImplements<InterfaceBinding> = .init()
    public let identity: IUnknown

    public init(identity: IUnknown) {
        self.identity = identity
    }

    public func toCOM() -> InterfaceBinding.ABIReference {
        implements.toCOM(embedder: self)
    }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case InterfaceBinding.interfaceID: return toCOM().cast()
            default: return try identity._queryInterface(id)
        }
    }
}
