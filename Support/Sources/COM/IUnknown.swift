import CWinRTCore

public protocol IUnknownProtocol: AnyObject {
    func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer
}
public typealias IUnknown = any IUnknownProtocol

extension IUnknownProtocol {
    public func _queryInterfacePointer<Projection: COMProjection>(_: Projection.Type) throws -> Projection.COMPointer {
        try _queryInterfacePointer(Projection.iid).withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
    }

    public func queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.SwiftObject {
        let comPointer = try self._queryInterfacePointer(Projection.self)
        return Projection.toSwift(transferringRef: comPointer)
    }

    public func tryQueryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.SwiftObject? {
       try NullResult.catch { try self.queryInterface(Projection.self) }
    }
}

public enum IUnknownProjection: COMTwoWayProjection {
    public typealias SwiftObject = IUnknown
    public typealias COMInterface = CWinRTCore.IUnknown
    public typealias COMVirtualTable = CWinRTCore.IUnknownVtbl

    public static let iid = IID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &Implementation.virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, implementation: Implementation.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, implementation: Implementation.self)
    }

    private final class Implementation: COMImport<IUnknownProjection> {
        public static var virtualTable: COMVirtualTable = .init(
            QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
            AddRef: { this in _addRef(this) },
            Release: { this in _release(this) })
    }
}