import COM_ABI

/// A COM tear-off object providing a COM virtual table for an interface implemented by the Swift owner object.
public final class COMDelegatingTearOff: COMEmbedderEx {
    private let owner: IUnknown
    private var comEmbedding: COMEmbedding
    public override var implementer: AnyObject { owner as AnyObject }

    public init(virtualTable: UnsafeRawPointer, owner: IUnknown) {
        self.comEmbedding = .init(virtualTable: virtualTable, embedder: nil)
        self.owner = owner
        super.init()
        self.comEmbedding.initEmbedder(self)
    }

    public convenience init<Binding: COMTwoWayBinding>(binding: Binding.Type, owner: Binding.SwiftObject) {
        self.init(virtualTable: Binding.virtualTablePointer, owner: owner as! IUnknown)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}