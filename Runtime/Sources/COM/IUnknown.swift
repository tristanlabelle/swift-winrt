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
