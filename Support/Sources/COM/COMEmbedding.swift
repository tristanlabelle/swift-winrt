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
    /// but delays setting the owner since "self" would not be available yet.
    /// `Never?` forces the caller to explicitly say `nil`.
    public init(virtualTable: VirtualTablePointer, owner: Never?) {
        self.abi = .init(virtualTable: virtualTable, swiftOwnerAndFlags: 0)
    }

    public var virtualTable: VirtualTablePointer? {
        get { abi.virtualTable }
    }

    public var owner: AnyObject? {
        get {
            UnsafeMutableRawPointer(bitPattern: abi.swiftOwnerAndFlags & ~SWRT_COMEmbedding_OwnerFlags_Mask)
                .map { Unmanaged<AnyObject>.fromOpaque($0).takeUnretainedValue() }
        }
    }

    /// Initializes the owner Swift object when it directly implements `IUnknown`.
    public mutating func initOwner(_ value: IUnknown) {
        if abi.swiftOwnerAndFlags != 0 {
            assert(self.owner === value, "COM embedding already has a different owner.")
        } else {
            abi.swiftOwnerAndFlags = UInt(bitPattern: Unmanaged<AnyObject>.passUnretained(value).toOpaque())
        }
    }

    /// Initializes the owner Swift object when it derives from `COMEmbedderEx`. 
    public mutating func initOwner(_ value: COMEmbedderEx) {
        if abi.swiftOwnerAndFlags != 0 {
            assert(self.owner === value, "COM embedding already has a different owner.")
        } else {
            // COMEmbedderEx provides the IUnknown implementation (directly or indirectly)
            // Verify that this property holds as we rely on it later.
            let opaquePointer = Unmanaged<COMEmbedderEx>.passUnretained(value).toOpaque()
            assert(opaquePointer == Unmanaged<AnyObject>.passUnretained(value).toOpaque(),
                "Reintrpret casting between Unmanaged<AnyObject> and Unmanaged<COMEmbedderEx> is unsafe.")
            abi.swiftOwnerAndFlags = UInt(bitPattern: opaquePointer) | SWRT_COMEmbedding_OwnerFlags_Extended
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        assert(abi.swiftOwnerAndFlags != 0, "Embedder must be initialized before using as a COM object.")
        return withUnsafeMutablePointer(to: &abi) { IUnknownPointer(OpaquePointer($0)) }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}
