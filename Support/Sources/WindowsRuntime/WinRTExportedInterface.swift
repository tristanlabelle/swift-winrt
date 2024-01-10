import COM
import CWinRTCore

/// Lays out a WinRT interface for exporting to WinRT consumers.
public struct WinRTExportedInterface {
    public static var null: WinRTExportedInterface { .init() }

    private var com: COMExportedInterface

    private init() {
        com = .null
    }

    public init<SwiftObject: IInspectableProtocol>(swiftObject: SwiftObject, virtualTable: IInspectableProjection.COMVirtualTablePointer) {
        com = .init(
            swiftObject: swiftObject,
            virtualTable: virtualTable.withMemoryRebound(to: IUnknownProjection.COMVirtualTable.self, capacity: 1) { $0 })
    }

    public var unknownPointer: IUnknownPointer {
        mutating get {
            com.pointer
        }
    }

    public var inspectablePointer: IInspectablePointer {
        mutating get {
            IInspectablePointer.cast(com.pointer)
        }
    }

    public static func unwrapUnsafe(_ this: IInspectablePointer) -> IInspectable {
        COMExportedInterface.unwrapObjectUnsafe(IUnknownPointer.cast(this)) as! IInspectable
    }

    public static func unwrap(_ this: IInspectablePointer) -> IInspectable? {
        COMExportedInterface.test(IUnknownPointer.cast(this)) ? unwrapUnsafe(this) : nil
    }
}

/// IInspectable virtual table implementations
extension WinRTExportedInterface {
    public static func AddRef<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        COMExportedInterface.AddRef(this)
    }

    public static func Release<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        COMExportedInterface.Release(this)
    }

    public static func QueryInterface<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ iid: UnsafePointer<CWinRTCore.SWRT_Guid>?,
            _ ppvObject: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> CWinRTCore.SWRT_HResult {
        COMExportedInterface.QueryInterface(this, iid, ppvObject)
    }

    public static func GetIids<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ count: UnsafeMutablePointer<UInt32>?,
            _ iids: UnsafeMutablePointer<UnsafeMutablePointer<CWinRTCore.SWRT_Guid>?>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let count, let iids else { return HResult.invalidArg.value }
        count.pointee = 0
        iids.pointee = nil
        let object = unwrapUnsafe(IInspectablePointer.cast(this))
        return HResult.catchValue {
            let idsArray = try object.getIids()
            let comArray = try WinRTArrayProjection<GUIDProjection>.toABI(idsArray)
            count.pointee = comArray.count
            iids.pointee = comArray.pointer
        }
    }

    public static func GetRuntimeClassName<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ className: UnsafeMutablePointer<CWinRTCore.SWRT_HString?>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let className else { return HResult.invalidArg.value }
        className.pointee = nil
        let object = unwrapUnsafe(IInspectablePointer.cast(this))
        return HResult.catchValue {
            className.pointee = try HStringProjection.toABI(object.getRuntimeClassName())
        }
    }

    public static func GetTrustLevel<Interface>(
            _ this: UnsafeMutablePointer<Interface>?,
            _ trustLevel: UnsafeMutablePointer<CWinRTCore.SWRT_TrustLevel>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let trustLevel else { return HResult.invalidArg.value }
        let object = unwrapUnsafe(IInspectablePointer.cast(this))
        return HResult.catchValue {
            trustLevel.pointee = try TrustLevel.toABI(object.getTrustLevel())
        }
    }
}