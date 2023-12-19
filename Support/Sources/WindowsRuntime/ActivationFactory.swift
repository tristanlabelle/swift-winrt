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