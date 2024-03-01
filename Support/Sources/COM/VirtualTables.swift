import WindowsRuntime_ABI

public func implementABIMethod<Interface, Implementation>(
        _ this: UnsafeMutablePointer<Interface>?, type: Implementation.Type,
        _ body: (Implementation) throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
    guard let this else {
        assertionFailure("COM this pointer was null")
        return HResult.pointer.value
    }

    let implementation: Implementation = COMExportBase.getImplementationUnsafe(this)
    return HResult.catchValue { try body(implementation) }
}