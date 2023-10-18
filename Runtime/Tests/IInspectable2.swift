import CABI
import WindowsRuntime

internal protocol IInspectable2Protocol: IInspectableProtocol {}
internal typealias IInspectable2 = any IInspectable2Protocol

internal final class IInspectable2Projection: WinRTProjectionBase<IInspectable2Projection>, WinRTTwoWayProjection,
        IInspectable2Protocol {
    public typealias SwiftValue = IInspectable2
    public typealias COMInterface = CABI.IInspectable
    public typealias VirtualTable = CABI.IInspectableVtbl

    public static let iid = IID(0xB6706A54, 0xCC67, 0x4090, 0x822D, 0xE165C8E36C11)
    public static var runtimeClassName: String { "IInspectable2" }
    public static var vtable: VirtualTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
    private static var vtableStruct: VirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        GetIids: { this, riid, ppvObject in _getIids(this, riid, ppvObject) },
        GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },
        GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) })
}