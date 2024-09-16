import COM

public typealias IBufferByteAccess = any IBufferByteAccessProtocol
public protocol IBufferByteAccessProtocol: IUnknownProtocol {
    var buffer: UnsafeMutablePointer<UInt8> { get throws }
}

import WindowsRuntime_ABI

public enum IBufferByteAccessBinding: COMTwoWayBinding {
    public typealias SwiftObject = IBufferByteAccess
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IBufferByteAccess

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IBufferByteAccessBinding>, IBufferByteAccessProtocol {
        public var buffer: UnsafeMutablePointer<UInt8> { get throws { try NullResult.unwrap(_interop.buffer()) } }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IBufferByteAccess_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        Buffer: { this, value in _implement(this) { try _set(value, $0.buffer) } })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IBufferByteAccess.Type) -> COMInterfaceID {
    .init(0x905A0FEF, 0xBC53, 0x11DF, 0x8C49, 0x001E4FC686DA)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IBufferByteAccess {
    public func buffer() throws -> UnsafeMutablePointer<UInt8>? {
        var value: UnsafeMutablePointer<UInt8>? = nil
        try COMError.fromABI(this.pointee.VirtualTable.pointee.Buffer(this, &value))
        return value
    }
}