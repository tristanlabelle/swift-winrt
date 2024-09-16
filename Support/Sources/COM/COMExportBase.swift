/// Provides derived classes with a COM-compatible representation,
/// such that they can be passed to C(++) APIs accepting COM interfaces.
/// Convenience base class for COMPrimaryExport and COMSecondaryExport.
open class COMExportBase<Binding: COMTwoWayBinding>: IUnknownProtocol {
    private var comEmbedding: COMEmbedding

    internal init() {
        comEmbedding = .uninitialized
        comEmbedding.initialize(embedder: self, virtualTable: Binding.virtualTablePointer)
    }

    public var unknownPointer: IUnknownPointer {
        comEmbedding.unknownPointer
    }

    public var comPointer: Binding.ABIPointer {
        Binding.ABIPointer(OpaquePointer(comEmbedding.unknownPointer))
    }

    public func toCOM() -> Binding.ABIReference { .init(addingRef: comPointer) }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        fatalError("Not implemented. Derived class should have overriden this method.")
    }
}
