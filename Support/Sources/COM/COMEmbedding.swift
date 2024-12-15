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
    /// `Never?` forces the caller to explicitly say `nil`.
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

    /// Initializes the embedder when it directly implements `IUnknown`.
    public mutating func initEmbedder(_ value: IUnknown) {
        if abi.swiftEmbedderAndFlags != 0 {
            assert(self.embedder === value, "COM object already embedded in a different object.")
        } else {
            abi.swiftEmbedderAndFlags = UInt(bitPattern: Unmanaged<AnyObject>.passUnretained(value).toOpaque())
        }
    }

    /// Initializes the embedder when it derives from `COMEmbedderEx`. 
    public mutating func initEmbedder(_ value: COMEmbedderEx) {
        if abi.swiftEmbedderAndFlags != 0 {
            assert(self.embedder === value, "COM object already embedded in a different object.")
        } else {
            // COMEmbedderEx provides the IUnknown implementation (directly or indirectly)
            // Verify that this property holds as we rely on it later.
            let opaquePointer = Unmanaged<COMEmbedderEx>.passUnretained(value).toOpaque()
            assert(opaquePointer == Unmanaged<AnyObject>.passUnretained(value).toOpaque(),
                "Reintrpret casting between Unmanaged<AnyObject> and Unmanaged<COMEmbedderEx> is unsafe.")
            abi.swiftEmbedderAndFlags = UInt(bitPattern: opaquePointer) | SWRT_COMEmbeddingFlags_Extended
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        assert(abi.swiftEmbedderAndFlags != 0, "Embedder must be initialized before using as a COM object.")
        return withUnsafeMutablePointer(to: &abi) { IUnknownPointer(OpaquePointer($0)) }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}
