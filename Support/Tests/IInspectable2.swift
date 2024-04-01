import WindowsRuntime_ABI
import WindowsRuntime

internal protocol IInspectable2Protocol: IInspectableProtocol {}
internal typealias IInspectable2 = any IInspectable2Protocol

internal enum IInspectable2Projection: WinRTInterfaceProjection {
    public typealias SwiftObject = IInspectable2
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IInspectable

    public static var typeName: String { "IInspectable2" }
    public static let interfaceID = COMInterfaceID(0xB6706A54, 0xCC67, 0x4090, 0x822D, 0xE165C8E36C11)
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IInspectable2Projection>, IInspectable2Protocol {}

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IInspectableVTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
        GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) })
}
