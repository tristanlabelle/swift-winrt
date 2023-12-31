import CWinRTCore

public protocol IWeakReferenceProtocol: IUnknownProtocol {
    func resolve() throws -> IInspectable?
}

public typealias IWeakReference = any IWeakReferenceProtocol

public enum IWeakReferenceProjection: COMTwoWayProjection {
    public typealias SwiftObject = IWeakReference
    public typealias COMInterface = CWinRTCore.SWRT_IWeakReference
    public typealias COMVirtualTable = CWinRTCore.SWRT_IWeakReferenceVTable

    public static let id = COMInterfaceID(0x00000037, 0x0000, 0x0000, 0xC000, 0x000000000046);
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: COMImport<IWeakReferenceProjection>, IWeakReferenceProtocol {
        public func resolve() throws -> IInspectable? {
            var iid = GUIDProjection.toABI(IInspectableProjection.id)
            var objectReference: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>?
            try HResult.throwIfFailed(_vtable.Resolve(comPointer, &iid, &objectReference))
            guard let objectReference else { return nil }
            return IInspectableProjection.toSwift(transferringRef: objectReference)
        }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
        Resolve: { this, iid, objectReference in _implement(this) {
            guard let iid, let objectReference else { throw HResult.Error.pointer }
            objectReference.pointee = nil
            let inspectable = try IInspectableProjection.toABI($0.resolve())
            defer { IUnknownPointer.release(inspectable) }
            guard let inspectable else { return }
            let result = try IUnknownPointer.cast(inspectable).queryInterface(GUIDProjection.toSwift(iid.pointee))
            objectReference.pointee = result.cast(to: CWinRTCore.SWRT_IInspectable.self)
        } })
}