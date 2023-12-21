import CWinRTCore
import WindowsRuntime

internal protocol IInspectable2Protocol: IInspectableProtocol {}
internal typealias IInspectable2 = any IInspectable2Protocol

internal enum IInspectable2Projection: WinRTTwoWayProjection {
    public typealias SwiftObject = IInspectable2
    public typealias COMInterface = CWinRTCore.SWRT_IInspectable
    public typealias COMVirtualTable = CWinRTCore.SWRT_IInspectableVTable

    public static let id = COMInterfaceID(0xB6706A54, 0xCC67, 0x4090, 0x822D, 0xE165C8E36C11)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
    public static var runtimeClassName: String { "IInspectable2" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        return toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        return try toCOM(object, importType: Import.self)
    }

    private final class Import: WinRTImport<IInspectable2Projection>, IInspectable2Protocol {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        GetIids: { this, riid, ppvObject in _getIids(this, riid, ppvObject) },
        GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },
        GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) })
}
