import WindowsRuntime_ABI
import COM

public typealias IBufferByteAccess = any IBufferByteAccessProtocol
public protocol IBufferByteAccessProtocol: IUnknownProtocol {
    var buffer: UnsafeMutablePointer<UInt8> { get throws }
}

public enum IBufferByteAccessProjection: COMTwoWayProjection {
    public typealias SwiftObject = IBufferByteAccess
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IBufferByteAccess
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_IBufferByteAccessVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
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

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IBufferByteAccess: @retroactive COMIUnknownStruct {}
#else
extension WindowsRuntime_ABI.SWRT_IBufferByteAccess: COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IBufferByteAccess {
    public static let iid = COMInterfaceID(0x905A0FEF, 0xBC53, 0x11DF, 0x8C49, 0x001E4FC686DA)
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IBufferByteAccess {
    public func buffer() throws -> UnsafeMutablePointer<UInt8>? {
        var value = UnsafeMutablePointer<UInt8>(bitPattern: 0)
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.Buffer(this, &value))
        return value
    }
}