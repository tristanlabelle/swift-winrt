import CWinRTCore
import COM

// Protocol for strongly-typed WinRT interface/delegate/runtimeclass projections into Swift.
public protocol WinRTProjection: COMProjection, IInspectableProtocol {
    static var runtimeClassName: String { get }
}

// Protocol for strongly-typed two-way WinRT interface/delegate/runtimeclass projections into and from Swift.
public protocol WinRTTwoWayProjection: WinRTProjection, COMTwoWayProjection {}
