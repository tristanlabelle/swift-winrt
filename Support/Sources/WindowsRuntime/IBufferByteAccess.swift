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

    public static var id: COMInterfaceID { COMInterop<COMInterface>.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IBufferByteAccessProjection>, IBufferByteAccessProtocol {
        public var buffer: UnsafeMutablePointer<UInt8> { get throws { try NullResult.unwrap(_interop.buffer()) } }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        Buffer: { this, value in _getter(this, value) { try $0.buffer } })
}

extension COMInterop where Interface == CWinRTCore.SWRT_IBufferByteAccess {
    public static let iid = COMInterfaceID(0x905A0FEF, 0xBC53, 0x11DF, 0x8C49, 0x001E4FC686DA)

    public func buffer() throws -> UnsafeMutablePointer<UInt8>? {
        var value = UnsafeMutablePointer<UInt8>(bitPattern: 0)
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.Buffer(this, &value))
        return value
    }
}