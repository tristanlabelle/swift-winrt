import CABI

// Base class for COM objects projected into Swift.
open class COMProjectionBase<Projection: COMProjection>: IUnknownProtocol {
    public let _pointer: Projection.COMInterfacePointer
    public var swiftValue: Projection.SwiftValue { self as! Projection.SwiftValue }

    public required init(transferringRef pointer: Projection.COMInterfacePointer) { self._pointer = pointer }
    deinit { IUnknownPointer.release(_pointer) }

    public func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        return try IUnknownPointer.cast(_pointer).queryInterface(iid)
    }
}
