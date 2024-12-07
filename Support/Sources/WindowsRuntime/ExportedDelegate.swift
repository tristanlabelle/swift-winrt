import COM

/// A COM-exported object delegating its implementation to a Swift object.
public final class ExportedDelegate<Binding: DelegateBinding>: IUnknownProtocol {
    private var comEmbedding: COMEmbeddingEx

    public init(_ closure: Binding.SwiftObject) {
        self.comEmbedding = .null // Required before referring to self
        self.comEmbedding = .init(
            virtualTable: Binding.virtualTablePointer,
            embedder: self,
            externalImplementer: closure as AnyObject)
    }

    public func toCOM() -> Binding.ABIReference {
        comEmbedding.toCOM().cast()
    }

    public func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            // Delegates are always agile and free-threaded.
            case Binding.interfaceID, IUnknownBinding.interfaceID, IAgileObjectBinding.interfaceID:
                return toCOM().cast()
            case FreeThreadedMarshalBinding.interfaceID:
                return try FreeThreadedMarshal(self).toCOM().cast()
            default:
                throw COMError.noInterface
        }
    }
}