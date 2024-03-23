import WindowsRuntime_ABI

public typealias IUnknown = any IUnknownProtocol
public protocol IUnknownProtocol: AnyObject {
    func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference
}

extension IUnknownProtocol {
    public func _queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> COMReference<Projection.COMInterface> {
        try _queryInterface(Projection.interfaceID).reinterpret()
    }

    public func queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.SwiftObject {
        let reference = try self._queryInterface(Projection.self)
        return Projection.toSwift(consume reference)
    }
}

public enum IUnknownProjection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IUnknown
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_IUnknownVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IUnknownProjection> {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) })
}

extension WindowsRuntime_ABI.SWRT_IUnknown: /* @retroactive */ COMIUnknownStruct {
    public static let iid = COMInterfaceID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
}

public typealias IUnknownPointer = IUnknownProjection.COMPointer
public typealias IUnknownReference = COMReference<IUnknownProjection.COMInterface>