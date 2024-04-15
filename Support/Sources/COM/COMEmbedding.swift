import WindowsRuntime_ABI

/// Protocol for Swift objects which embed COM interfaces.
public protocol COMEmbedderWithDelegatedImplementation: IUnknownProtocol {
    /// Gets the Swift object implementating the COM interface (often the same as self)
    var delegatedImplementation: AnyObject { get }
}

/// Declare as a stored property of a Swift object to embed a COM object representation which shares its reference count.
/// This allows the embedder object to be referenced both in Swift and in COM.
/// A Swift object can have multiple COM embeddings if it implements multiple COM interfaces.
public struct COMEmbedding /*: ~Copyable */ {
    // Should be ~Copyable, but this causes a Swift 5.9 compiler bug on Windows for some uses:
    // "error: copy of noncopyable typed value"

    // This type must refer to the embedder that creates it,
    // so it cannot be initialized in one go because "self" isn't available yet.
    // Instead, it is initialized in two steps: first to an invalid value, and then to a valid value.
    public static var uninitialized: COMEmbedding { .init() }

    private var comObject: WindowsRuntime_ABI.SWRT_SwiftCOMObject

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

    fileprivate static func toUnmanagedUnsafe<Interface>(_ this: UnsafeMutablePointer<Interface>) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: WindowsRuntime_ABI.SWRT_SwiftCOMObject.self, capacity: 1) {
            Unmanaged<AnyObject>.fromOpaque($0.pointee.swiftObject)
        }
    }

    public static func test<Interface>(_ this: UnsafeMutablePointer<Interface>) -> Bool {
        do { _ = try COMInterop(this).queryInterface(WindowsRuntime_ABI.SWRT_SwiftCOMObject.iid) } catch { return false }
        return true
    }

    /// Gets the Swift object that embeds a given COM interface, 
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getEmbedderObjectOrCrash<Interface>(_ this: UnsafeMutablePointer<Interface>) -> AnyObject {
        toUnmanagedUnsafe(this).takeUnretainedValue()
    }

    public static func getEmbedderObject<Interface>(_ this: UnsafeMutablePointer<Interface>) -> AnyObject? {
        test(this) ? getEmbedderObjectOrCrash(this) : nil
    }

    /// Gets the Swift object that provides the implementation for the given COM interface,
    /// assuming that it is an embedded COM interface, and otherwise crashes.
    public static func getImplementationOrCrash<Interface, Implementation>(
            _ this: UnsafeMutablePointer<Interface>, type: Implementation.Type = Implementation.self) -> Implementation {
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

    public static func getImplementation<Interface, Implementation>(
            _ this: UnsafeMutablePointer<Interface>, type: Implementation.Type = Implementation.self) -> Implementation? {
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

extension WindowsRuntime_ABI.SWRT_SwiftCOMObject {
    internal static var iid: COMInterfaceID { .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64) }
}

public enum IUnknownVirtualTable {
    public static func AddRef<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }
        let unmanaged = COMEmbedding.toUnmanagedUnsafe(IUnknownPointer(OpaquePointer(this)))
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
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

    public static func QueryInterface<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ iid: UnsafePointer<WindowsRuntime_ABI.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this, let iid, let ppvObject else { return HResult.invalidArg.value }
        ppvObject.pointee = nil

        return HResult.catchValue {
            let id = GUIDProjection.toSwift(iid.pointee)
            let this = IUnknownPointer(OpaquePointer(this))
            let reference = id == WindowsRuntime_ABI.SWRT_SwiftCOMObject.iid
                ? IUnknownReference(addingRef: this)
                : try (COMEmbedding.getEmbedderObjectOrCrash(this) as! IUnknown)._queryInterface(id)
            ppvObject.pointee = UnsafeMutableRawPointer(reference.detach())
        }
    }
}
