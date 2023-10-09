import CABI

public final class WinRTInitialization {
    public init(multithreaded: Bool) throws {
        CABI.RoInitialize(multithreaded ? CABI.RO_INIT_MULTITHREADED  : CABI.RO_INIT_SINGLETHREADED)
    }

    deinit {
        CABI.RoUninitialize()
    }
}