import WindowsRuntime_ABI
import COM

internal protocol IUnknown2Protocol: IUnknownProtocol {}
internal typealias IUnknown2 = any IUnknown2Protocol

internal enum IUnknown2Projection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown2
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IUnknown

    public static let interfaceID = COMInterfaceID(0x5CF9DEB3, 0xD7C6, 0x42A9, 0x85B3, 0x61D8B68A7B2A)
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IUnknown2Projection>, IUnknown2Protocol {}

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IUnknownVTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) })
}