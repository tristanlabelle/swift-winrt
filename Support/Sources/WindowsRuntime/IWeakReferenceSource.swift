import WindowsRuntime_ABI

public typealias IWeakReferenceSource = any IWeakReferenceSourceProtocol
public protocol IWeakReferenceSourceProtocol: IUnknownProtocol {
    func getWeakReference() throws -> IWeakReference
}

public enum IWeakReferenceSourceProjection: COMTwoWayProjection {
    public typealias SwiftObject = IWeakReferenceSource
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IWeakReferenceSource
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_IWeakReferenceSourceVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IWeakReferenceSourceProjection>, IWeakReferenceSourceProtocol {
        public func getWeakReference() throws -> IWeakReference {
            try NullResult.unwrap(_interop.getWeakReference())
        }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetWeakReference: { this, weakReference in _getter(this, weakReference) { try IWeakReferenceProjection.toABI($0.getWeakReference()) } })
}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IWeakReferenceSource: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IWeakReferenceSource: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0x00000038, 0x0000, 0x0000, 0xC000, 0x000000000046);
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IWeakReferenceSource {
    public func getWeakReference() throws -> IWeakReference? {
        var value = IWeakReferenceProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetWeakReference(this, &value))
        return IWeakReferenceProjection.toSwift(consuming: &value)
    }
}