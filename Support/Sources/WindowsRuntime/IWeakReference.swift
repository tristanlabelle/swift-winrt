import WindowsRuntime_ABI

public protocol IWeakReferenceProtocol: IUnknownProtocol {
    func resolve() throws -> IInspectable?
}

public typealias IWeakReference = any IWeakReferenceProtocol

public enum IWeakReferenceProjection: COMTwoWayProjection {
    public typealias SwiftObject = IWeakReference
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IWeakReference
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_IWeakReferenceVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IWeakReferenceProjection>, IWeakReferenceProtocol {
        public func resolve() throws -> IInspectable? {
            try _interop.resolve(IInspectableProjection.interfaceID)
        }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        Resolve: { this, iid, objectReference in _implement(this) {
            guard let iid, let objectReference else { throw HResult.Error.pointer }
            objectReference.pointee = nil
            var inspectable = try IInspectableProjection.toABI($0.resolve())
            defer { IInspectableProjection.release(&inspectable) }
            guard let inspectable else { return }
            let targetUnknown = try COMInterop(inspectable).queryInterface(GUIDProjection.toSwift(iid.pointee))
            let target = targetUnknown.reinterpret(to: WindowsRuntime_ABI.SWRT_IInspectable.self)
            objectReference.pointee = target.detach()
        } })
}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IWeakReference: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IWeakReference: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0x00000037, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IWeakReference {
    public func resolve(_ iid: COMInterfaceID) throws -> IInspectable? {
        var iid = GUIDProjection.toABI(iid)
        var objectReference = IInspectableProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.Resolve(this, &iid, &objectReference))
        return IInspectableProjection.toSwift(consuming: &objectReference)
    }
}