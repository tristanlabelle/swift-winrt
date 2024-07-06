import WindowsRuntime_ABI

public typealias IUnknown = any IUnknownProtocol
public protocol IUnknownProtocol: AnyObject {
    func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference
}

extension IUnknownProtocol {
    public func _queryInterface<Interface /* COMIUnknownStruct */>(
            _ id: COMInterfaceID, type: Interface.Type = Interface.self) throws -> COMReference<Interface> {
        (try _queryInterface(id) as IUnknownReference).cast(to: type)
    }

    public func _queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> COMReference<Projection.COMInterface> {
        try _queryInterface(Projection.interfaceID)
    }

    public func queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.SwiftObject {
        Projection.toSwift(try self._queryInterface(Projection.self))
    }
}

public enum IUnknownProjection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IUnknown

    public static var interfaceID: COMInterfaceID { uuidof(COMInterface.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IUnknownProjection> {}

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IUnknown_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) })
}

// Originally we extended SWRT_IUnknown to add a static let COMInterfaceID property,
// however this breaks down when a second Swift module has its own copy of the SWRT_IUnknown
// and references SWRT_IUnknown.iid. The Swift compiler then doesn't find the extension.
public func uuidof(_: WindowsRuntime_ABI.SWRT_IUnknown.Type) -> COMInterfaceID {
    .init(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
}

public typealias IUnknownPointer = IUnknownProjection.COMPointer
public typealias IUnknownReference = COMReference<IUnknownProjection.COMInterface>