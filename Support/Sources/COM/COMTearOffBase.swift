/// A COM-exported object providing a secondary interface to a primary exported object.
open class COMTearOffBase<InterfaceBinding: COMTwoWayBinding>: IUnknownProtocol {
    private var implements: COMImplements<InterfaceBinding> = .init()
    public let owner: IUnknown

    public init(owner: IUnknown) {
        self.owner = owner
    }

    public func toCOM() -> InterfaceBinding.ABIReference {
        implements.toCOM(embedder: self)
    }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case InterfaceBinding.interfaceID: return toCOM().cast()
            default: return try owner._queryInterface(id)
        }
    }
}
