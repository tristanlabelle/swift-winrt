/// A COM-exported object providing a secondary interface to a primary exported object.
open class COMSecondaryExport<Projection: COMTwoWayProjection>: COMExportBase<Projection> {
    public let identity: IUnknown

    public init(identity: IUnknown) {
        self.identity = identity
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            case Projection.interfaceID: return toCOM().cast()
            default: return try identity._queryInterface(id)
        }
    }

    public static func delegating(to target: IUnknown) -> COMSecondaryExport<Projection> {
        precondition(target is Projection.SwiftObject)
        return COMDelegatingExport<Projection>(target: target)
    }
}

fileprivate class COMDelegatingExport<Projection: COMTwoWayProjection>: COMSecondaryExport<Projection>, COMEmbedderWithDelegatedImplementation {
    init(target: IUnknown) { super.init(identity: target) }
    var delegatedImplementation: AnyObject { identity }
}
