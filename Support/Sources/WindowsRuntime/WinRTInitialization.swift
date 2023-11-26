import CWinRTCore

// Initializes WinRT for the current thread.
public final class WinRTInitialization {
    public init(multithreaded: Bool) throws {
        CWinRTCore.SWRT_RoInitialize(multithreaded
            ? CWinRTCore.SWRT_RO_INIT_MULTITHREADED
            : CWinRTCore.SWRT_RO_INIT_SINGLETHREADED)
    }

    deinit {
        CWinRTCore.SWRT_RoUninitialize()
    }
}