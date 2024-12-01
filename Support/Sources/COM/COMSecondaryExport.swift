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
}

public class COMDelegatingExport: COMEmbedderWithDelegatedImplementation {
    private var comEmbedding: COMEmbedding
    public let delegatedImplementation: AnyObject

    public init(virtualTable: UnsafeRawPointer, implementer: IUnknown) {
        comEmbedding = .uninitialized
        delegatedImplementation = implementer
        comEmbedding.initialize(embedder: self, virtualTable: virtualTable)
    }

    public convenience init<Binding: COMTwoWayBinding>(binding: Binding.Type, implementer: Binding.SwiftObject) {
        self.init(virtualTable: Binding.virtualTablePointer, implementer: implementer as! IUnknown)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}
