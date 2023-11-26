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
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &Implementation.virtualTable) { $0 } }
    public static var runtimeClassName: String { "IInspectable" }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, implementation: Implementation.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, implementation: Implementation.self)
    }

    private final class Implementation: WinRTImport<IInspectableProjection> {
        public static var virtualTable: COMVirtualTable = .init(
            QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
            AddRef: { this in _addRef(this) },
            Release: { this in _release(this) },
            GetIids: { this, riid, ppvObject in _getIids(this, riid, ppvObject) },
            GetRuntimeClassName: { this, className in _getRuntimeClassName(this, className) },
            GetTrustLevel: { this, trustLevel in _getTrustLevel(this, trustLevel) })
    }
}