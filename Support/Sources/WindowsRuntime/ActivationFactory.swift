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