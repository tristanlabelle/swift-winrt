import CWinRTCore

public final class WinRTInitialization {
    public init(multithreaded: Bool) throws {
        CWinRTCore.RoInitialize(multithreaded ? CWinRTCore.RO_INIT_MULTITHREADED  : CWinRTCore.RO_INIT_SINGLETHREADED)
    }

    deinit {
        CWinRTCore.RoUninitialize()
    }
}