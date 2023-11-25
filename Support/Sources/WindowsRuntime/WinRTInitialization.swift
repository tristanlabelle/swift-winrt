import CWinRTCore

// Initializes WinRT for the current thread.
public final class WinRTInitialization {
    public init(multithreaded: Bool) throws {
        CWinRTCore.ABI_RoInitialize(multithreaded
            ? CWinRTCore.ABI_RO_INIT_MULTITHREADED
            : CWinRTCore.ABI_RO_INIT_SINGLETHREADED)
    }

    deinit {
        CWinRTCore.ABI_RoUninitialize()
    }
}