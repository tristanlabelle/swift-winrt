import COM_ABI
import COM_PrivateABI

/// Use as a stored property in a Swift object to embed a COM object
/// representation which shares its reference count and delegates the implementation.
public struct COMEmbeddingEx: ~Copyable {
    private var abi: SWRT_COMEmbeddingEx

    public static var null: COMEmbeddingEx { .init() }

    private init() {
        self.abi = .init()
    }

    public init(virtualTable: UnsafeRawPointer, embedder: AnyObject, externalImplementer: AnyObject) {
        // The don't reference count the embedder since this object is part of it.
        // Do reference the implementer since it's an object external to the embedder.
        // They can't be the same or we'd have a reference cycle.
        assert(externalImplementer !== embedder, "The implementer object should be external to the embedder object.")
        self.abi = .init(
            base: .init(
                virtualTable: virtualTable,
                swiftEmbedderAndFlags: UInt(bitPattern: Unmanaged.passUnretained(embedder).toOpaque())
                    | SWRT_COMEmbeddingFlags_ExternalImplementer
                    | (embedder is IUnknown ? 0 : SWRT_COMEmbeddingFlags_ExternalImplementerIsIUnknown)),
            swiftImplementer_retained: Unmanaged<AnyObject>.passRetained(externalImplementer).toOpaque())
    }

    deinit {
        if let implementerOpaquePointer = abi.swiftImplementer_retained {
            Unmanaged<AnyObject>.fromOpaque(implementerOpaquePointer).release()
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        withUnsafeMutablePointer(to: &abi) {
            IUnknownPointer(OpaquePointer($0))
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}
