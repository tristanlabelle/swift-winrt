import WindowsRuntime_ABI

/// Lays out a COM interface for exporting to COM consumers.
public struct COMExportedInterface {
    private static let markerInterfaceId: COMInterfaceID = .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
    public static var uninitialized: COMExportedInterface { .init() }

    private var comObject: WindowsRuntime_ABI.SWRT_SwiftCOMObject

    private init() {
        comObject = .init()
    }

    public init<SwiftObject: IUnknownProtocol>(
            swiftObject: SwiftObject,
            virtualTable: UnsafeRawPointer) {
        comObject = .init(virtualTable: virtualTable,
            swiftObject: Unmanaged<AnyObject>.passUnretained(swiftObject).toOpaque())
    }

    private init(virtualTable: UnsafeRawPointer) {
        comObject = .init(virtualTable: virtualTable, swiftObject: nil)
    }

    public static func withLateSwiftObjectInit(virtualTable: UnsafeRawPointer) -> COMExportedInterface {
        .init(virtualTable: virtualTable)
    }

    public mutating func _lateInitSwiftObject<SwiftObject: IUnknownProtocol>(_ swiftObject: SwiftObject) {
        comObject.swiftObject = Unmanaged<AnyObject>.passUnretained(swiftObject).toOpaque()
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
        do { _ = try COMInterop(this).queryInterface(markerInterfaceId) } catch { return false }
        return true
    }

    public static func unwrapUnsafe<Interface>(_ this: UnsafeMutablePointer<Interface>) -> AnyObject {
        toUnmanagedUnsafe(this).takeUnretainedValue()
    }

    public static func unwrap<Interface>(_ this: UnsafeMutablePointer<Interface>) -> AnyObject? {
        test(this) ? unwrapUnsafe(this) : nil
    }
}

// IUnknown virtual table implementations
extension COMExportedInterface {
    public static func AddRef<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 1
        }

        let unmanaged = toUnmanagedUnsafe(IUnknownPointer(OpaquePointer(this)))
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }

        let unmanaged = toUnmanagedUnsafe(IUnknownPointer(OpaquePointer(this)))
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    public static func QueryInterface<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ iid: UnsafePointer<WindowsRuntime_ABI.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        guard let ppvObject else { return HResult.pointer.value }
        ppvObject.pointee = nil

        guard let iid else { return HResult.pointer.value }

        return HResult.catchValue {
            let id = GUIDProjection.toSwift(iid.pointee)
            let this = IUnknownPointer(OpaquePointer(this))
            let reference = id == markerInterfaceId
                ? IUnknownReference(addingRef: this)
                : try (unwrapUnsafe(this) as! IUnknown)._queryInterface(id)
            ppvObject.pointee = UnsafeMutableRawPointer(reference.detach())
        }
    }
}
