import COM_ABI

/// Protocol for Swift objects which embed COM interfaces.
public protocol COMEmbedderWithDelegatedImplementation: AnyObject {
    /// Gets the Swift object implementating the COM interface (often the same as self)
    var delegatedImplementation: AnyObject { get }
}

/// SWRT_COMEmbedding should be stored as a property of a Swift object
/// to embed a COM object representation which shares its reference count.
/// In most cases, this is done via the `COMImplements<InterfaceBinding>` struct.
extension SWRT_COMEmbedding {
    public init(virtualTable: UnsafeRawPointer, swiftEmbedder: AnyObject) {
        self.init(
            virtualTable: virtualTable,
            swiftEmbedder: Unmanaged<AnyObject>.passUnretained(swiftEmbedder).toOpaque())
    }

    public var hasSwiftEmbedder: Bool { swiftEmbedder != nil }

    public mutating func initSwiftEmbedder(_ value: AnyObject) {
        if let currentValue = self.swiftEmbedder {
            assert(Unmanaged<AnyObject>.fromOpaque(currentValue).takeUnretainedValue() === value,
                "COM object already embedded in a different object.")
        } else {
            self.swiftEmbedder = Unmanaged<AnyObject>.passUnretained(value).toOpaque()
        }
    }

    public mutating func asUnknownPointer() -> IUnknownPointer {
        withUnsafeMutablePointer(to: &self) {
            IUnknownPointer(OpaquePointer($0))
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: asUnknownPointer()) }
}

/// Declare as a stored property of a Swift object to embed a COM object representation which shares its reference count.
/// This allows the embedder object to be referenced both in Swift and in COM.
/// A Swift object can have multiple COM embeddings if it implements multiple COM interfaces.
public enum COMEmbedding {
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
