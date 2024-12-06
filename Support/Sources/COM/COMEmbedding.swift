import COM_ABI
import COM_PrivateABI

/// Protocol for Swift objects which embed COM interfaces.
public protocol COMEmbedderWithDelegatedImplementation: AnyObject {
    /// Gets the Swift object implementating the COM interface (often the same as self)
    var delegatedImplementation: AnyObject { get }
}

/// Use as a stored property in a Swift object to embed a COM object
/// representation which shares its reference count.
/// In most cases, this is done via the `COMImplements<InterfaceBinding>` struct.
public struct COMEmbedding: ~Copyable {
    private var abi: SWRT_COMEmbedding

    public static var null: COMEmbedding { .init() }

    private init() {
        self.abi = SWRT_COMEmbedding(virtualTable: nil, swiftEmbedder: nil)
    }

    /// Initializes an instance with a virtual table,
    /// but delays setting the embedder since "self" wouldn't be available yet.
    public init(virtualTable: UnsafeRawPointer, embedder: Never?) {
        self.abi = SWRT_COMEmbedding(virtualTable: virtualTable, swiftEmbedder: nil)
    }

    public var virtualTable: UnsafeRawPointer? {
        get { abi.virtualTable }
    }

    public var embedder: AnyObject? {
        get { abi.swiftEmbedder.map { Unmanaged<AnyObject>.fromOpaque($0).takeUnretainedValue() } }
    }

    public mutating func initEmbedder(_ value: AnyObject) {
        if let currentValue = abi.swiftEmbedder {
            assert(Unmanaged<AnyObject>.fromOpaque(currentValue).takeUnretainedValue() === value,
                "COM object already embedded in a different object.")
        } else {
            abi.swiftEmbedder = Unmanaged<AnyObject>.passUnretained(value).toOpaque()
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        withUnsafeMutablePointer(to: &self) {
            IUnknownPointer(OpaquePointer($0))
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}

extension COMEmbedding {
    fileprivate static func getUnmanagedEmbedderUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: SWRT_COMEmbedding.self, capacity: 1) {
            Unmanaged<AnyObject>.fromOpaque($0.pointee.swiftEmbedder)
        }
    }

    public static func test<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Bool {
        do { _ = try COMInterop(this).queryInterface(uuidof(SWRT_COMEmbedding.self)) } catch { return false }
        return true
    }

    /// Gets the Swift object that embeds a given COM interface, 
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getEmbedderOrCrash<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> AnyObject {
        getUnmanagedEmbedderUnsafe(this).takeUnretainedValue()
    }

    public static func getEmbedder<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> AnyObject? {
        test(this) ? getEmbedderOrCrash(this) : nil
    }

    /// Gets the Swift object that provides the implementation for the given COM interface,
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getImplementationOrCrash<ABIStruct, Implementation>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementation.Type = Implementation.self) -> Implementation {
        let embedderObject = getUnmanagedEmbedderUnsafe(this).takeUnretainedValue()
        // Typical case: the embedder provides the implementation
        if let implementation = embedderObject as? Implementation { return implementation }
        // Less common case: the embedder delegates the implementation
        if let embedder = embedderObject as? COMEmbedderWithDelegatedImplementation,
                let implementation = embedder.delegatedImplementation as? Implementation {
            return implementation
        }
        fatalError("COM object does not provide the expected implementation")
    }

    public static func getImplementation<ABIStruct, Implementation>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementation.Type = Implementation.self) -> Implementation? {
        guard test(this) else { return nil }
        let embedderObject = getUnmanagedEmbedderUnsafe(this).takeUnretainedValue()
        // Typical case: the embedder provides the implementation
        if let implementation = embedderObject as? Implementation { return implementation }
        // Less common case: the embedder delegates the implementation
        if let embedder = embedderObject as? COMEmbedderWithDelegatedImplementation,
                let implementation = embedder.delegatedImplementation as? Implementation {
            return implementation
        }
        return nil
    }
}

internal func uuidof(_: SWRT_COMEmbedding.Type) -> COMInterfaceID {
    .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
}

public enum IUnknownVirtualTable {
    public static func AddRef<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        let unmanaged = COMEmbedding.getUnmanagedEmbedderUnsafe(this)
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        let unmanaged = COMEmbedding.getUnmanagedEmbedderUnsafe(this)
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    public static func QueryInterface<ABIStruct>(
            _ this: UnsafeMutablePointer<ABIStruct>?,
            _ iid: UnsafePointer<COM_ABI.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> COM_ABI.SWRT_HResult {
        guard let this, let iid, let ppvObject else { return COMError.toABI(hresult: HResult.invalidArg) }
        ppvObject.pointee = nil

        return COMError.toABI {
            let id = GUIDBinding.fromABI(iid.pointee)
            let this = IUnknownPointer(OpaquePointer(this))
            let reference = id == uuidof(SWRT_COMEmbedding.self)
                ? IUnknownReference(addingRef: this)
                : try (COMEmbedding.getEmbedderOrCrash(this) as! IUnknown)._queryInterface(id)
            ppvObject.pointee = UnsafeMutableRawPointer(reference.detach())
        }
    }
}
