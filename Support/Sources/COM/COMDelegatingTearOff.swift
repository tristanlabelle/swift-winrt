import COM_ABI

/// A COM tear-off object providing a COM virtual table for an interface implemented by the Swift owner object.
public final class COMDelegatingTearOff: COMEmbedderEx {
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