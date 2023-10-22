import CWinRTCore
import COM

public protocol IBufferByteAccessProtocol: IUnknownProtocol {
    var buffer: UnsafeMutablePointer<UInt8> { get throws }
}
public typealias IBufferByteAccess = any IBufferByteAccessProtocol

public final class IBufferByteAccessProjection:
        COMProjectionBase<IBufferByteAccessProjection>, COMTwoWayProjection,
        IBufferByteAccessProtocol {
    public typealias SwiftObject = IBufferByteAccess
    public typealias COMInterface = CWinRTCore.IBufferByteAccess
    public typealias COMVirtualTable = CWinRTCore.IBufferByteAccessVtbl

    public static let iid = IID(0x905A0FEF, 0xBC53, 0x11DF, 0x8C49, 0x001E4FC686DA)
    public static var vtable: COMVirtualTablePointer { withUnsafePointer(to: &vtableStruct) { $0 } }
    private static var vtableStruct: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        Buffer: { this, value in _getter(this, value) { try $0.buffer } }
    )

    public var buffer: UnsafeMutablePointer<UInt8> { get throws { try NullResult.unwrap(_getter(_vtable.Buffer)) } }
}