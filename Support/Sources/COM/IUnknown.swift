import CWinRTCore

public protocol IUnknownProtocol: AnyObject {
    func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer
}
public typealias IUnknown = any IUnknownProtocol

extension IUnknownProtocol {
    public func _queryInterfacePointer<Projection: COMProjection>(_: Projection.Type) throws -> Projection.COMPointer {
        try _queryInterfacePointer(Projection.interfaceID).withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
    }

    public func queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.SwiftObject {
        let comPointer = try self._queryInterfacePointer(Projection.self)
        return Projection.toSwift(transferringRef: comPointer)
    }
}

public enum IUnknownProjection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = CWinRTCore.SWRT_IUnknown
    public typealias COMVirtualTable = CWinRTCore.SWRT_IUnknownVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IUnknownProjection> {}

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) })
}

extension CWinRTCore.SWRT_IUnknown: /* @retroactive */ COMIUnknownStruct {
    public static let iid = COMInterfaceID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
}