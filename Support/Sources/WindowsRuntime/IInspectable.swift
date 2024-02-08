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

    public static var id: COMInterfaceID { COMInterop<COMInterface>.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
    public static var runtimeClassName: String { "IInspectable" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IInspectableProjection> {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
        GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) })
}

extension COMInterop where Interface == CWinRTCore.SWRT_IInspectable {
    public static let iid = COMInterfaceID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
}