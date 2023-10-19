import CABI
import COM

// Protocol for strongly-typed WinRT interface/delegate/runtimeclass projections into Swift.
public protocol WinRTProjection: COMProjection, IInspectableProtocol {
    static var runtimeClassName: String { get }
}

// Protocol for strongly-typed two-way WinRT interface/delegate/runtimeclass projections into and from Swift.
public protocol WinRTTwoWayProjection: WinRTProjection, COMTwoWayProjection {}

extension WinRTProjection {
    public static func _getActivationFactory<COMInterface>(activatableId: String, iid: IID) throws -> UnsafeMutablePointer<COMInterface> {
        let activatableId = try HSTRING.create(Self.runtimeClassName)
        defer { HSTRING.delete(activatableId) }
        var iid = iid
        var factory: UnsafeMutableRawPointer?
        try HResult.throwIfFailed(CABI.RoGetActivationFactory(activatableId, &iid, &factory))
        guard let factory else { throw HResult.Error.noInterface }
        return factory.bindMemory(to: COMInterface.self, capacity: 1)
    }
}
