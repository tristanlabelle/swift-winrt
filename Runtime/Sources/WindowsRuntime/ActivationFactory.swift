import CWinRTCore
import COM

public enum ActivationFactory {
    public static func getPointer<COMInterface>(activatableId: String, iid: IID) throws -> UnsafeMutablePointer<COMInterface> {
        let activatableId = try HStringProjection.toABI(activatableId)
        defer { HStringProjection.release(activatableId) }
        var iid = iid
        var factory: UnsafeMutableRawPointer?
        try HResult.throwIfFailed(CWinRTCore.RoGetActivationFactory(activatableId, &iid, &factory))
        guard let factory else { throw HResult.Error.noInterface }
        return factory.bindMemory(to: COMInterface.self, capacity: 1)
    }
}