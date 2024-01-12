import CWinRTCore

/// Lays out a COM interface for exporting to COM consumers.
public struct COMExportedInterface {
    private static let markerInterfaceId: COMInterfaceID = .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
    public static var uninitialized: COMExportedInterface { .init() }

    private var comObject: CWinRTCore.SWRT_SwiftCOMObject

    private init() {
        comObject = .init()
    }

    public init<SwiftObject: IUnknownProtocol, VirtualTable>(
            swiftObject: SwiftObject,
            virtualTable: UnsafePointer<VirtualTable>) {
        comObject = .init(
            comVirtualTable: virtualTable.withMemoryRebound(to: CWinRTCore.SWRT_IUnknownVTable.self, capacity: 1) { $0 },
            swiftObject: Unmanaged<AnyObject>.passUnretained(swiftObject).toOpaque())
    }

    public var isInitialized: Bool { comObject.swiftObject != nil }

    public var unknownPointer: IUnknownPointer {
        mutating get {
            withUnsafeMutablePointer(to: &comObject) {
                IUnknownPointer.cast($0)
            }
        }
    }

    fileprivate static func toUnmanagedUnsafe<Interface>(_ this: UnsafeMutablePointer<Interface>) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: CWinRTCore.SWRT_SwiftCOMObject.self, capacity: 1) {
            Unmanaged<AnyObject>.fromOpaque($0.pointee.swiftObject)
        }
    }

    public static func test<Interface>(_ this: UnsafeMutablePointer<Interface>) -> Bool {
        do { try IUnknownPointer.cast(this).queryInterface(markerInterfaceId).release() } catch { return false }
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

        let unmanaged = toUnmanagedUnsafe(IUnknownPointer.cast(this))
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    public static func Release<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return 0
        }

        let unmanaged = toUnmanagedUnsafe(IUnknownPointer.cast(this))
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    public static func QueryInterface<Interface>(
        _ this: UnsafeMutablePointer<Interface>?,
            _ iid: UnsafePointer<CWinRTCore.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> CWinRTCore.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        guard let ppvObject else { return HResult.pointer.value }
        ppvObject.pointee = nil

        guard let iid else { return HResult.pointer.value }

        return HResult.catchValue {
            let id = GUIDProjection.toSwift(iid.pointee)
            let this = IUnknownPointer.cast(this)
            let unknownWithRef = id == markerInterfaceId
                ? this.addingRef()
                : try (unwrapUnsafe(this) as! IUnknown)._queryInterfacePointer(id)
            ppvObject.pointee = UnsafeMutableRawPointer(unknownWithRef)
        }
    }
}
