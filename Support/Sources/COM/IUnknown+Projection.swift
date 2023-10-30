import CWinRTCore

public final class IUnknownProjection: COMProjectionBase<IUnknownProjection>, COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = CWinRTCore.IUnknown
    public typealias COMVirtualTable = CWinRTCore.IUnknownVtbl

    public static let iid = IID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }
    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) }
    )
}