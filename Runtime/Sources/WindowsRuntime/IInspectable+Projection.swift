import CWinRTCore
import COM

public final class IInspectableProjection: WinRTProjectionBase<IInspectableProjection>, WinRTTwoWayProjection {
    public typealias SwiftObject = IInspectable
    public typealias COMInterface = CWinRTCore.IInspectable
    public typealias COMVirtualTable = CWinRTCore.IInspectableVtbl

    public static let iid = IID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
    public static var runtimeClassName: String { "" }
    public static var vtable: COMVirtualTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
    private static var vtableStruct: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        GetIids: { this, riid, ppvObject in _getIids(this, riid, ppvObject) },
        GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },
        GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) }
    )
}