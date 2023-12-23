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
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: COMImport<IWeakReferenceSourceProjection>, IWeakReferenceSourceProtocol {
        public func getWeakReference() throws -> IWeakReference {
            try NullResult.unwrap(_getter(_vtable.GetWeakReference, IWeakReferenceProjection.self))
        }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        GetWeakReference: { this, weakReference in _getter(this, weakReference) { try IWeakReferenceProjection.toABI($0.getWeakReference()) } })
}