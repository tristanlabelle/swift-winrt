import CWinRTCore

// Base class for COM objects projected into Swift.
open class COMProjectionBase<Projection: COMProjection>: IUnknownProtocol {
    public let comPointer: Projection.COMPointer
    public var swiftObject: Projection.SwiftObject { self as! Projection.SwiftObject }

    public required init(transferringRef pointer: Projection.COMPointer) { self.comPointer = pointer }
    deinit { IUnknownPointer.release(comPointer) }

    public func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        return try IUnknownPointer.cast(comPointer).queryInterface(iid)
    }
}
