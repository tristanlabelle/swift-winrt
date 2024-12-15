import COM_ABI

/// Use as a stored property of a class to allow the object to be referenced
/// as a COM object exposing a given interface.
public struct COMImplements<InterfaceBinding: COMTwoWayBinding>: ~Copyable {
    private var embedding: COMEmbedding = .init(virtualTable: InterfaceBinding.virtualTablePointer, embedder: nil)

    public init() {}

    public mutating func toCOM(embedder: InterfaceBinding.SwiftObject) -> InterfaceBinding.ABIReference {
        // The embedder should conform to IUnknownProtocol and hence be an AnyObject,
        // but this cannot be expressed in the type system.
        toCOM(embedder: embedder as! IUnknown)
    }

    internal mutating func toCOM(embedder: IUnknown) -> InterfaceBinding.ABIReference {
        embedding.initEmbedder(embedder)
        return embedding.toCOM().cast()
    }
}