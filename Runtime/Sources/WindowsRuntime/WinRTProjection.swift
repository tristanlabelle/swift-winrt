import CABI
import COM

// Protocol for strongly-typed WinRT interface/delegate/runtimeclass projections into Swift.
public protocol WinRTProjection: COMProjection, IInspectableProtocol {
    static var runtimeClassName: String { get }
}

// Protocol for strongly-typed two-way WinRT interface/delegate/runtimeclass projections into and from Swift.
public protocol WinRTTwoWayProjection: WinRTProjection, COMTwoWayProjection {}

extension WinRTProjection {
    public static func _getActivationFactory<Factory: WinRTProjection>(_: Factory.Type) throws -> Factory.SwiftValue {
        let activatableId = try HSTRING.create(Self.runtimeClassName)
        defer { HSTRING.delete(activatableId) }
        var iid = Factory.iid
        var factory: UnsafeMutableRawPointer?
        try HResult.throwIfFailed(CABI.RoGetActivationFactory(activatableId, &iid, &factory))
        guard let factory else { throw HResult.Error.noInterface }
        return Factory.toSwift(consuming: factory.bindMemory(to: Factory.COMInterface.self, capacity: 1))
    }
}
