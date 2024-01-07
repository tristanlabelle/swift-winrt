import CWinRTCore

/// Lays out a COM interface for exporting to COM consumers.
public struct COMExportedInterface {
    private static let markerInterfaceId: COMInterfaceID = .init(0x33934271, 0x7009, 0x4EF3, 0x90F1, 0x02090D7EBD64)
    public static var null: COMExportedInterface { .init() }

    private var comObject: CWinRTCore.SWRT_SwiftCOMObject

    private init() {
        comObject = .init()
    }

    public init<SwiftObject: IUnknownProtocol>(swiftObject: SwiftObject, virtualTable: IUnknownProjection.COMVirtualTablePointer) {
        comObject = .init(
            comVirtualTable: virtualTable,
            swiftObject: Unmanaged<AnyObject>.passUnretained(swiftObject).toOpaque())
    }

    public var pointer: IUnknownPointer {
        mutating get {
            withUnsafeMutablePointer(to: &comObject) {
                IUnknownPointer.cast($0)
            }
        }
    }

    private static func toUnmanagedUnsafe(_ this: IUnknownPointer) -> Unmanaged<AnyObject> {
        this.withMemoryRebound(to: CWinRTCore.SWRT_SwiftCOMObject.self, capacity: 1) {
            Unmanaged<AnyObject>.fromOpaque($0.pointee.swiftObject)
        }
    }

    public static func test(_ this: IUnknownPointer) -> Bool {
        do { try this.queryInterface(markerInterfaceId).release() } catch { return false }
        return true
    }

    public static func unwrapObjectUnsafe(_ this: IUnknownPointer) -> AnyObject {
        toUnmanagedUnsafe(this).takeUnretainedValue()
    }

    public static func unwrapObject(_ this: IUnknownPointer) -> AnyObject? {
        test(this) ? unwrapUnsafe(this) : nil
    }

    public static func unwrapUnsafe(_ this: IUnknownPointer) -> IUnknown {
        unwrapObjectUnsafe(this) as! IUnknown
    }

    public static func unwrap(_ this: IUnknownPointer) -> IUnknown? {
        test(this) ? unwrapUnsafe(this) : nil
    }

    @discardableResult
    public static func addRefUnsafe(_ this: IUnknownPointer) -> UInt32 {
        let unmanaged = toUnmanagedUnsafe(this)
        _ = unmanaged.retain()
        // Best effort refcount
        return UInt32(_getRetainCount(unmanaged.takeUnretainedValue()))
    }

    @discardableResult
    internal static func releaseUnsafe(_ this: IUnknownPointer) -> UInt32 {
        let unmanaged = toUnmanagedUnsafe(this)
        let oldRetainCount = _getRetainCount(unmanaged.takeUnretainedValue())
        unmanaged.release()
        // Best effort refcount
        return UInt32(oldRetainCount - 1)
    }

    @discardableResult
    internal static func queryInterfaceUnsafe(_ this: IUnknownPointer, _ id: COMInterfaceID) throws -> IUnknownPointer {
        id == markerInterfaceId ? this.addingRef() : try unwrapUnsafe(this)._queryInterfacePointer(id)
    }
}
