import CWinRTCore
import COM

public protocol IBufferByteAccessProtocol: IUnknownProtocol {
    var buffer: UnsafeMutablePointer<UInt8> { get throws }
}
public typealias IBufferByteAccess = any IBufferByteAccessProtocol

public enum IBufferByteAccessProjection: COMTwoWayProjection {
    public typealias SwiftObject = IBufferByteAccess
    public typealias COMInterface = CWinRTCore.SWRT_IBufferByteAccess
    public typealias COMVirtualTable = CWinRTCore.SWRT_IBufferByteAccessVTable

    public static let id = COMInterfaceID(0x905A0FEF, 0xBC53, 0x11DF, 0x8C49, 0x001E4FC686DA)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: COMImport<IBufferByteAccessProjection>, IBufferByteAccessProtocol {
        public var buffer: UnsafeMutablePointer<UInt8> { get throws { try NullResult.unwrap(_getter(_vtable.Buffer)) } }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        Buffer: { this, value in _getter(this, value) { try $0.buffer } })
}