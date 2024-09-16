/// A COM-exported object providing a secondary interface to a primary exported object.
open class COMSecondaryExport<Binding: COMTwoWayBinding>: COMExportBase<Binding> {
    public let identity: IUnknown

    public init(identity: IUnknown) {
        self.identity = identity
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Binding.interfaceID: return toCOM().cast()
            default: return try identity._queryInterface(id)
        }
    }

    public static func delegating(to target: IUnknown) -> COMSecondaryExport<Binding> {
        precondition(target is Binding.SwiftObject)
        return COMDelegatingExport<Binding>(target: target)
    }
}

fileprivate class COMDelegatingExport<Binding: COMTwoWayBinding>: COMSecondaryExport<Binding>, COMEmbedderWithDelegatedImplementation {
    init(target: IUnknown) { super.init(identity: target) }
    var delegatedImplementation: AnyObject { identity }
}
