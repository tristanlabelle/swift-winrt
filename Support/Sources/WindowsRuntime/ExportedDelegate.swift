import COM

/// A COM-exported object delegating its implementation to a Swift object.
public final class ExportedDelegate<Binding: DelegateBinding>: COMEmbedderEx, IUnknownProtocol {
    private var comEmbedding: COMEmbedding

    public init(_ closure: Binding.SwiftObject) {
        self.comEmbedding = .init(virtualTable: Binding.exportedVirtualTable, owner: nil)
        super.init(implementer: closure as AnyObject)
        self.comEmbedding.initOwner(self as COMEmbedderEx)
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
            case ISupportErrorInfoBinding.interfaceID:
                return SupportErrorInfoForAllInterfaces(owner: self).toCOM().cast()
            default:
                throw COMError.noInterface
        }
    }
}