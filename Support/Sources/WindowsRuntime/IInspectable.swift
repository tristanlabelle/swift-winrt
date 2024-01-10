import COM
import CWinRTCore

public protocol IInspectableProtocol: IUnknownProtocol {
    func getIids() throws -> [COMInterfaceID]
    func getRuntimeClassName() throws -> String
    func getTrustLevel() throws -> TrustLevel
}
public typealias IInspectable = any IInspectableProtocol

public enum IInspectableProjection: WinRTTwoWayProjection {
    public typealias SwiftObject = IInspectable
    public typealias COMInterface = CWinRTCore.SWRT_IInspectable
    public typealias COMVirtualTable = CWinRTCore.SWRT_IInspectableVTable

    public static let id = COMInterfaceID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
    public static var runtimeClassName: String { "IInspectable" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: WinRTImport<IInspectableProjection> {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in WinRTExportedInterface.QueryInterface(this, iid, ppvObject) },
        AddRef: { this in WinRTExportedInterface.AddRef(this) },
        Release: { this in WinRTExportedInterface.Release(this) },
        GetIids: { this, riid, ppvObject in WinRTExportedInterface.GetIids(this, riid, ppvObject) },
        GetRuntimeClassName: { this, className in WinRTExportedInterface.GetRuntimeClassName(this, className) },
        GetTrustLevel: { this, trustLevel in WinRTExportedInterface.GetTrustLevel(this, trustLevel) })
}