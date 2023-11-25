import CWinRTCore
import COM

internal protocol IUnknown2Protocol: IUnknownProtocol {}
internal typealias IUnknown2 = any IUnknown2Protocol

internal enum IUnknown2Projection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown2
    public typealias COMInterface = CWinRTCore.ABI_IUnknown
    public typealias COMVirtualTable = CWinRTCore.ABI_IUnknownVTable

    public static let id = COMInterfaceID(0x5CF9DEB3, 0xD7C6, 0x42A9, 0x85B3, 0x61D8B68A7B2A)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &Implementation.virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        return toSwift(transferringRef: comPointer, implementation: Implementation.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        return try toCOM(object, implementation: Implementation.self)
    }

    private final class Implementation: COMImport<IUnknown2Projection>, IUnknown2Protocol {
        public static var virtualTable: COMVirtualTable = .init(
            QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
            AddRef: { this in _addRef(this) },
            Release: { this in _release(this) })
    }
}