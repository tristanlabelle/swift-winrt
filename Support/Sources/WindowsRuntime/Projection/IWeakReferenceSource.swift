import COM

public typealias IWeakReferenceSource = any IWeakReferenceSourceProtocol
public protocol IWeakReferenceSourceProtocol: IUnknownProtocol {
    func getWeakReference() throws -> IWeakReference
}

import WindowsRuntime_ABI

public enum IWeakReferenceSourceBinding: COMTwoWayBinding {
    public typealias SwiftObject = IWeakReferenceSource
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IWeakReferenceSource

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IWeakReferenceSourceBinding>, IWeakReferenceSourceProtocol {
        public func getWeakReference() throws -> IWeakReference {
            try NullResult.unwrap(_interop.getWeakReference())
        }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IWeakReferenceSource_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetWeakReference: { this, weakReference in _implement(this) { try _set(weakReference, IWeakReferenceBinding.toABI($0.getWeakReference())) } })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IWeakReferenceSource.Type) -> COMInterfaceID {
    .init(0x00000038, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IWeakReferenceSource {
    public func getWeakReference() throws -> IWeakReference? {
        var value = IWeakReferenceBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetWeakReference(this, &value))
        return IWeakReferenceBinding.fromABI(consuming: &value)
    }
}