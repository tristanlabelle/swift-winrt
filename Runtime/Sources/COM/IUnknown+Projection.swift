import CABI

public final class IUnknownProjection: COMProjectionBase<IUnknownProjection>, COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = CABI.IUnknown
    public typealias VirtualTable = CABI.IUnknownVtbl

    public static let iid = IID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
    public static var vtable: VirtualTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
    private static var vtableStruct: VirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) }
    )
}