import COM

public typealias IWeakReference = any IWeakReferenceProtocol
public protocol IWeakReferenceProtocol: IUnknownProtocol {
    func resolve() throws -> IInspectable?
}

import WindowsRuntime_ABI

public enum IWeakReferenceBinding: COMTwoWayBinding {
    public typealias SwiftObject = IWeakReference
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IWeakReference

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IWeakReferenceBinding>, IWeakReferenceProtocol {
        public func resolve() throws -> IInspectable? {
            try _interop.resolve(IInspectableBinding.interfaceID)
        }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IWeakReference_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        Resolve: { this, iid, objectReference in _implement(this) {
            guard let iid, let objectReference else { throw COMError.pointer }
            objectReference.pointee = nil
            var inspectable = try IInspectableBinding.toABI($0.resolve())
            defer { IInspectableBinding.release(&inspectable) }
            guard let inspectable else { return }
            objectReference.pointee = try COMInterop(inspectable)
                .queryInterface(GUIDBinding.toSwift(iid.pointee), type: SWRT_IInspectable.self)
                .detach()
        } })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IWeakReference.Type) -> COMInterfaceID {
    .init(0x00000037, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IWeakReference {
    public func resolve(_ iid: COMInterfaceID) throws -> IInspectable? {
        var iid = GUIDBinding.toABI(iid)
        var objectReference = IInspectableBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.Resolve(this, &iid, &objectReference))
        return IInspectableBinding.toSwift(consuming: &objectReference)
    }
}