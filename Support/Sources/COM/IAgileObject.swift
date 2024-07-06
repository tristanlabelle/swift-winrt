import WindowsRuntime_ABI

/// Projection for the IAgileObject interface.
/// This is a marker interface which we automatically implement for all COM projections,
/// so we don't need to expose a protocol type for it or a two-way projection.
public enum IAgileObjectProjection: COMProjection {
    public typealias SwiftObject = IUnknown // Avoid introducing an interface for IAgileObject since it is a marker interface.
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IAgileObject

    public static var interfaceID: COMInterfaceID { uuidof(COMInterface.self) }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        IUnknownProjection._wrap(reference.cast())
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try object._queryInterface(Self.self)
    }
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IAgileObject.Type) -> COMInterfaceID {
    .init(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)
}