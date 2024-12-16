import COM

/// A COM-exported object delegating its implementation to a Swift object.
public final class ExportedDelegate<Binding: DelegateBinding>: COMEmbedderEx, IUnknownProtocol {
    private let closureObject: AnyObject
    private var comEmbedding: COMEmbedding

    public override var implementer: AnyObject { closureObject }

    public init(_ closure: Binding.SwiftObject) {
        self.comEmbedding = .init(virtualTable: Binding.virtualTablePointer, embedder: nil)
        self.closureObject = closure as AnyObject
        super.init()
        self.comEmbedding.initEmbedder(self as COMEmbedderEx)
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