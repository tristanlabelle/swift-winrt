import CWinRTCore

public protocol IWeakReferenceSourceProtocol: IUnknownProtocol {
    func getWeakReference() throws -> IWeakReference
}

public typealias IWeakReferenceSource = any IWeakReferenceSourceProtocol

public enum IWeakReferenceSourceProjection: COMTwoWayProjection {
    public typealias SwiftObject = IWeakReferenceSource
    public typealias COMInterface = CWinRTCore.SWRT_IWeakReferenceSource
    public typealias COMVirtualTable = CWinRTCore.SWRT_IWeakReferenceSourceVTable

    public static let id = COMInterfaceID(0x00000038, 0x0000, 0x0000, 0xC000, 0x000000000046);
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
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

extension COMInterop where Interface == CWinRTCore.SWRT_IWeakReferenceSource {
    public func getWeakReference() throws -> IWeakReference? {
        var value = IWeakReferenceProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetWeakReference(this, &value))
        return IWeakReferenceProjection.toSwift(consuming: &value)
    }
}