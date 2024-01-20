import CWinRTCore
import COM

public func getActivationFactoryPointer<COMInterface>(activatableId: String, id: COMInterfaceID) throws -> UnsafeMutablePointer<COMInterface> {
    var activatableId = try HStringProjection.toABI(activatableId)
    defer { HStringProjection.release(&activatableId) }

    var iid = GUIDProjection.toABI(id)
    var factory: UnsafeMutableRawPointer?
    try WinRTError.throwIfFailed(CWinRTCore.SWRT_RoGetActivationFactory(activatableId, &iid, &factory))
    guard let factory else { throw HResult.Error.noInterface }

    return factory.bindMemory(to: COMInterface.self, capacity: 1)
}

public func lazyInitActivationFactoryPointer<COMInterface>(
        _ pointer: inout UnsafeMutablePointer<COMInterface>?,
        activatableId: String,
        id: COMInterfaceID) throws -> UnsafeMutablePointer<COMInterface> {
    if let existing = pointer { return existing }
    let new: UnsafeMutablePointer<COMInterface> = try getActivationFactoryPointer(activatableId: activatableId, id: id)
    pointer = new
    return new
}

extension UnsafeMutablePointer where Pointee == CWinRTCore.SWRT_IActivationFactory {
    public func activateInstance() throws -> IInspectablePointer {
        var inspectable: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>? = nil
        try WinRTError.throwIfFailed(self.pointee.lpVtbl.pointee.ActivateInstance(self, &inspectable))
        guard let inspectable else { throw COM.HResult.Error.noInterface }
        return inspectable
    }

    public func activateInstance<Projection: WinRTProjection>(projection: Projection.Type) throws -> Projection.COMPointer {
        try IUnknownPointer.queryInterface(try activateInstance(), projection)
    }
}