import COM_ABI

/// Exposes a secondary COM interface whose implementation is delegated to a primary Swift exported object.
public final class COMDelegatingExport: COMEmbedderEx {
    private var comEmbedding: COMEmbedding

    public init(virtualTable: UnsafeRawPointer, implementer: IUnknown) {
        comEmbedding = .init(virtualTable: virtualTable, embedder: nil)
        super.init(implementer: implementer)
        comEmbedding.initEmbedder(self)
    }

    public convenience init<Binding: COMTwoWayBinding>(binding: Binding.Type, implementer: Binding.SwiftObject) {
        self.init(virtualTable: Binding.virtualTablePointer, implementer: implementer as! IUnknown)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}