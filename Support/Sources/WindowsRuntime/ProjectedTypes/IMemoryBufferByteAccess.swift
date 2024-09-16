import COM

public typealias IMemoryBufferByteAccess = any IMemoryBufferByteAccessProtocol
public protocol IMemoryBufferByteAccessProtocol: IUnknownProtocol {
    var buffer: UnsafeMutableBufferPointer<UInt8> { get throws }
}

import WindowsRuntime_ABI

public enum IMemoryBufferByteAccessBinding: COMTwoWayBinding {
    public typealias SwiftObject = IMemoryBufferByteAccess
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IMemoryBufferByteAccess

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IMemoryBufferByteAccessBinding>, IMemoryBufferByteAccessProtocol {
        public var buffer: UnsafeMutableBufferPointer<UInt8> { get throws { try NullResult.unwrap(_interop.getBuffer()) } }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IMemoryBufferByteAccess_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetBuffer: { this, value, capacity in _implement(this) { this in
            guard let value, let capacity else { throw COMError.pointer }
            let buffer = try this.buffer
            value.pointee = buffer.baseAddress
            capacity.pointee = UInt32(buffer.count)
        } })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IMemoryBufferByteAccess.Type) -> COMInterfaceID {
    .init(0x5B0D3235, 0x4DBA, 0x4D44, 0x865E, 0x8F1D0E4FD04D)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IMemoryBufferByteAccess {
    public func getBuffer() throws -> UnsafeMutableBufferPointer<UInt8>? {
        var value: UnsafeMutablePointer<UInt8>? = nil
        var capacity: UInt32 = 0
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetBuffer(this, &value, &capacity))
        return UnsafeMutableBufferPointer(start: value, count: Int(capacity))
    }
}