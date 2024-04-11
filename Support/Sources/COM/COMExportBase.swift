/// Convenience base class for COMPrimaryExport and COMSecondaryExport.
open class COMExportBase<Projection: COMTwoWayProjection>: IUnknownProtocol {
    private var comEmbedding: COMEmbedding

    internal init() {
        comEmbedding = .uninitialized
        comEmbedding.initialize(embedder: self, virtualTable: Projection.virtualTablePointer)
    }

    public var unknownPointer: IUnknownPointer {
        comEmbedding.unknownPointer
    }

    public var comPointer: Projection.COMPointer {
        Projection.COMPointer(OpaquePointer(comEmbedding.unknownPointer))
    }

    public func toCOM() -> COMReference<Projection.COMInterface> { .init(addingRef: comPointer) }

    open func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        fatalError("Not implemented. Derived class should have overriden this method.")
    }
}
