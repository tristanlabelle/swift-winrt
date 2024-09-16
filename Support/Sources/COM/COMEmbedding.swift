import COM_ABI
import SWRT_SwiftCOMObject

/// Protocol for Swift objects which embed COM interfaces.
public protocol COMEmbedderWithDelegatedImplementation: IUnknownProtocol {
    /// Gets the Swift object implementating the COM interface (often the same as self)
    var delegatedImplementation: AnyObject { get }
}

/// Declare as a stored property of a Swift object to embed a COM object representation which shares its reference count.
/// This allows the embedder object to be referenced both in Swift and in COM.
/// A Swift object can have multiple COM embeddings if it implements multiple COM interfaces.
public struct COMEmbedding: ~Copyable {
    // This type must refer to the embedder that creates it,
    // so it cannot be initialized in one go because "self" isn't available yet.
    // Instead, it is initialized in two steps: first to an invalid value, and then to a valid value.
    public static var uninitialized: COMEmbedding { .init() }

    private var comObject: SWRT_SwiftCOMObject

    private init() {
        comObject = .init()
    }

    public mutating func initialize<Embedder: IUnknownProtocol>(embedder: Embedder, virtualTable: UnsafeRawPointer) {
        comObject.virtualTable = virtualTable
        comObject.swiftObject = Unmanaged<AnyObject>.passUnretained(embedder).toOpaque()
    }

    public var isInitialized: Bool { comObject.swiftObject != nil }

    public var unknownPointer: IUnknownPointer {
        mutating get {
            withUnsafeMutablePointer(to: &comObject) {
                IUnknownPointer(OpaquePointer($0))
            }
        }
    }

    public mutating func toCOM() -> IUnknownReference { .init(addingRef: unknownPointer) }

    fileprivate static func toUnmanagedUnsafe<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: SWRT_SwiftCOMObject.self, capacity: 1) {
            Unmanaged<AnyObject>.fromOpaque($0.pointee.swiftObject)
        }
    }

    public static func test<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> Bool {
        do { _ = try COMInterop(this).queryInterface(uuidof(SWRT_SwiftCOMObject.self)) } catch { return false }
        return true
    }

    /// Gets the Swift object that embeds a given COM interface, 
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getEmbedderObjectOrCrash<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> AnyObject {
        toUnmanagedUnsafe(this).takeUnretainedValue()
    }

    public static func getEmbedderObject<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>) -> AnyObject? {
        test(this) ? getEmbedderObjectOrCrash(this) : nil
    }

    /// Gets the Swift object that provides the implementation for the given COM interface,
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getImplementationOrCrash<ABIStruct, Implementation>(
            _ this: UnsafeMutablePointer<ABIStruct>, type: Implementation.Type = Implementation.self) -> Implementation {
        let embedderObject = toUnmanagedUnsafe(this).takeUnretainedValue()
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
        let embedderObject = toUnmanagedUnsafe(this).takeUnretainedValue()
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

internal func uuidof(_: SWRT_SwiftCOMObject.Type) -> COMInterfaceID {
    .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
}

public enum IUnknownVirtualTable {
    public static func AddRef<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        let unmanaged = COMEmbedding.toUnmanagedUnsafe(IUnknownPointer(OpaquePointer(this)))
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<ABIStruct>(_ this: UnsafeMutablePointer<ABIStruct>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        let unmanaged = COMEmbedding.toUnmanagedUnsafe(IUnknownPointer(OpaquePointer(this)))
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
            let id = GUIDBinding.toSwift(iid.pointee)
            let this = IUnknownPointer(OpaquePointer(this))
            let reference = id == uuidof(SWRT_SwiftCOMObject.self)
                ? IUnknownReference(addingRef: this)
                : try (COMEmbedding.getEmbedderObjectOrCrash(this) as! IUnknown)._queryInterface(id)
            ppvObject.pointee = UnsafeMutableRawPointer(reference.detach())
        }
    }
}
