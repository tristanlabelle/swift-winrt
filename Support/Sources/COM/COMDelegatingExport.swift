import COM_ABI

/// Exposes a secondary COM interface whose implementation is delegated to a primary Swift exported object.
public final class COMDelegatingExport {
    private var comEmbedding: COMEmbeddingEx

    public init(virtualTable: UnsafeRawPointer, implementer: IUnknown) {
        comEmbedding = .null // Required before referring to self
        comEmbedding = .init(virtualTable: virtualTable, embedder: self, implementer: implementer)
    }

    public convenience init<Binding: COMTwoWayBinding>(binding: Binding.Type, implementer: Binding.SwiftObject) {
        self.init(virtualTable: Binding.virtualTablePointer, implementer: implementer as! IUnknown)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}