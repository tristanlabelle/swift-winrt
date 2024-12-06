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

    public init(virtualTable: UnsafeRawPointer, embedder: AnyObject, implementer: AnyObject) {
        self.abi = .init(
            base: .init(
                virtualTable: virtualTable,
                swiftEmbedderAndFlags: UInt(bitPattern: Unmanaged.passUnretained(embedder).toOpaque())
                    | SWRT_COMEmbeddingFlags_SeparateImplementer
                    | (embedder is IUnknown ? 0 : SWRT_COMEmbeddingFlags_ImplementerIsIUnknown)),
            swiftImplementer: Unmanaged<AnyObject>.passUnretained(implementer).toOpaque())
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        withUnsafeMutablePointer(to: &abi) {
            IUnknownPointer(OpaquePointer($0))
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}
