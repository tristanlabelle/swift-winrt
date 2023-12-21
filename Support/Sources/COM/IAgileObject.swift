import CWinRTCore
import struct Foundation.UUID

public protocol IAgileObjectProtocol: IUnknownProtocol {}

public typealias IAgileObject = any IAgileObjectProtocol

public enum IAgileObjectProjection: COMTwoWayProjection {
    public typealias SwiftObject = IAgileObject
    public typealias COMInterface = CWinRTCore.SWRT_IAgileObject
    public typealias COMVirtualTable = CWinRTCore.SWRT_IAgileObjectVTable

    public static let id = COMInterfaceID(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: COMImport<IAgileObjectProjection>, IAgileObjectProtocol {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) }
    )
}