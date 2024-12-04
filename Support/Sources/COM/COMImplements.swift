/// Use as a stored property of a class to allow the object to be referenced
/// as a COM object exposing a given interface.
public struct COMImplements<InterfaceBinding: COMTwoWayBinding>: ~Copyable {
    private var embedding: COMEmbedding = .uninitialized

    public mutating func toCOM(embedder: InterfaceBinding.SwiftObject) -> InterfaceBinding.ABIReference {
        // The embedder should conform to IUnknownProtocol and hence be an AnyObject,
        // but this cannot be expressed in the type system.
        toCOM(embedder: embedder as! IUnknown)
    }

    internal mutating func toCOM(embedder: AnyObject) -> InterfaceBinding.ABIReference {
        if embedding.isInitialized {
            assert(embedding.embedder === embedder, "COM object already embedded in another object.")
        } else {
            // Thread safe since every initialization will produce the same state and has no side-effects.
            assert(embedder is InterfaceBinding.SwiftObject || embedder is COMEmbedderWithDelegatedImplementation,
                "Embedder \(type(of: embedder)) does not conform to the expected interface \(InterfaceBinding.self).")
            embedding.initialize(embedder: embedder, virtualTable: InterfaceBinding.virtualTablePointer)
        }

        return embedding.toCOM().cast()
    }
}