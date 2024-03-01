import WindowsRuntime_ABI

// Initializes WinRT for the current thread.
public final class WinRTInitialization {
    public init(multithreaded: Bool) throws {
        WindowsRuntime_ABI.SWRT_RoInitialize(multithreaded
            ? WindowsRuntime_ABI.SWRT_RO_INIT_MULTITHREADED
            : WindowsRuntime_ABI.SWRT_RO_INIT_SINGLETHREADED)
    }

    deinit {
        WindowsRuntime_ABI.SWRT_RoUninitialize()
    }
}