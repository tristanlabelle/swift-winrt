import COM_ABI

/// A COM tear-off object providing a COM virtual table for an interface implemented by the Swift owner object.
public final class COMDelegatingTearOff: COMEmbedderEx {
    private var comEmbedding: COMEmbedding

    public init(owner: IUnknown, virtualTable: VirtualTablePointer) {
        comEmbedding = .init(virtualTable: virtualTable, owner: nil)
        super.init(implementer: owner)
        comEmbedding.initOwner(self)
    }

    public convenience init<Binding: COMTwoWayBinding>(owner: Binding.SwiftObject, binding: Binding.Type) {
        self.init(owner: owner as! IUnknown, virtualTable: Binding.exportedVirtualTable)
    }

    public func toCOM() -> IUnknownReference { comEmbedding.toCOM() }
}