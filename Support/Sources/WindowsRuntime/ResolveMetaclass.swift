import WindowsRuntime_ABI

public typealias ResolveMetaclass = (_ runtimeClass: String) throws -> IInspectableReference

/// Resolves the metaclass from a runtime class name using the system default strategy: RoGetActivationFactory.
public func defaultResolveMetaclass(runtimeClass: String) throws -> IInspectableReference {
    var activatableId = try WinRTPrimitiveProjection.String.toABI(runtimeClass)
    defer { WinRTPrimitiveProjection.String.release(&activatableId) }

    var iid = GUIDProjection.toABI(IInspectableProjection.interfaceID)
    var rawPointer: UnsafeMutableRawPointer?
    try WinRTError.throwIfFailed(WindowsRuntime_ABI.SWRT_RoGetActivationFactory(activatableId, &iid, &rawPointer))
    guard let rawPointer else { throw HResult.Error.noInterface }

    return COM.COMReference(transferringRef: rawPointer.bindMemory(to: SWRT_IInspectable.self, capacity: 1))
}
