import CABI

public final class IUnknownProjection: COMProjectionBase<IUnknownProjection>, COMTwoWayProjection {
    public typealias SwiftValue = IUnknown
    public typealias CStruct = CABI.IUnknown
    public typealias CVTableStruct = CABI.IUnknownVtbl

    public static let iid = IID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
    public static var vtable: CVTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
    private static var vtableStruct: CVTableStruct = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) }
    )
}