import COM_ABI
import COM_PrivateABI

/// Use as a stored property in a Swift object to embed a COM object
/// representation which shares its reference count.
/// In most cases, this is done via the `COMImplements<InterfaceBinding>` struct.
public struct COMEmbedding: ~Copyable {
    private var abi: SWRT_COMEmbedding

    public static var null: COMEmbedding { .init() }

    private init() {
        self.abi = .init()
    }

    /// Initializes an instance with a virtual table,
    /// but delays setting the embedder since "self" wouldn't be available yet.
    public init(virtualTable: UnsafeRawPointer, embedder: Never?) {
        self.abi = .init(virtualTable: virtualTable, swiftEmbedderAndFlags: 0)
    }

    public var virtualTable: UnsafeRawPointer? {
        get { abi.virtualTable }
    }

    public var embedder: AnyObject? {
        get {
            UnsafeMutableRawPointer(bitPattern: abi.swiftEmbedderAndFlags & ~SWRT_COMEmbeddingFlags_Mask)
                .map { Unmanaged<AnyObject>.fromOpaque($0).takeUnretainedValue() }
        }
    }

    public mutating func initEmbedder(_ value: AnyObject) {
        if abi.swiftEmbedderAndFlags != 0 {
            assert(self.embedder === value, "COM object already embedded in a different object.")
        } else {
            abi.swiftEmbedderAndFlags = UInt(bitPattern: Unmanaged<AnyObject>.passUnretained(value).toOpaque())
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        withUnsafeMutablePointer(to: &abi) {
            IUnknownPointer(OpaquePointer($0))
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}
