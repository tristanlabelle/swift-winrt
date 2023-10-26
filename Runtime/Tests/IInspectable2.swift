import CWinRTCore
import WindowsRuntime

internal protocol IInspectable2Protocol: IInspectableProtocol {}
internal typealias IInspectable2 = any IInspectable2Protocol

internal final class IInspectable2Projection: WinRTProjectionBase<IInspectable2Projection>, WinRTTwoWayProjection,
        IInspectable2Protocol {
    public typealias SwiftObject = IInspectable2
    public typealias COMInterface = CWinRTCore.IInspectable
    public typealias COMVirtualTable = CWinRTCore.IInspectableVtbl

    public static let iid = IID(0xB6706A54, 0xCC67, 0x4090, 0x822D, 0xE165C8E36C11)
    public static var runtimeClassName: String { "IInspectable2" }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        GetIids: { this, riid, ppvObject in _getIids(this, riid, ppvObject) },
        GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },
        GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) })
}