/// Use as a stored property of a class to allow the object to be referenced
/// as a COM object exposing a given interface.
/// Logically ~Copyable, but Swift 5.10 constraints prevent it.
public struct COMImplements<InterfaceBinding: COMTwoWayBinding> /* : ~Copyable */ {
    private var embedding: COMEmbedding = .uninitialized

    internal mutating func toCOM(embedder: AnyObject) -> InterfaceBinding.ABIReference {
        if !embedding.isInitialized {
            embedding.initialize(embedder: embedder, virtualTable: InterfaceBinding.virtualTablePointer)
        }

        return InterfaceBinding.ABIReference(addingRef: InterfaceBinding.ABIPointer(OpaquePointer(embedding.unknownPointer)))
    }
}