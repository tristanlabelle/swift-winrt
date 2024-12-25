import COM_ABI

/// A COM tear-off object providing a COM virtual table for an interface implemented by the Swift owner object.
public final class COMDelegatingTearOff: COMEmbedderEx {
    private var comEmbedding: COMEmbedding

    public init(virtualTable: UnsafeRawPointer, owner: IUnknown) {
        comEmbedding = .init(virtualTable: virtualTable, owner: nil)
        super.init(implementer: owner)
        comEmbedding.initOwner(self)
    }

    public convenience init<Binding: COMTwoWayBinding>(binding: Binding.Type, owner: Binding.SwiftObject) {
        self.init(virtualTable: Binding.virtualTablePointer, owner: owner as! IUnknown)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}