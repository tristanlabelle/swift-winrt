import CWinRTCore
import COM

// Protocol for strongly-typed WinRT interface/delegate/runtimeclass projections into Swift.
public protocol WinRTProjection: COMProjection {
    static var runtimeClassName: String { get }
}
