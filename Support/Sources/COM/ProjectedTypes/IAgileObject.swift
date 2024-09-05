import COM_ABI

/// Projection for the IAgileObject COM interface, which marks an object as supporting agile marshaling.
/// IAgileObject is a marker interface with no methods over IUnknown's, so it does not need its own virtual table.
/// This means we can piggyback on the IUnknown virtual table to transparently implement IAgileObject,
/// so we don't need to expose a protocol type for it or a two-way projection.
public enum IAgileObjectProjection: COMProjection {
    public typealias SwiftObject = IUnknown // Avoid introducing an interface for IAgileObject since it is a marker interface.
    public typealias ABIStruct = COM_ABI.SWRT_IAgileObject

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        IUnknownProjection._wrap(reference.cast())
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try object._queryInterface(Self.self)
    }
}

public func uuidof(_: COM_ABI.SWRT_IAgileObject.Type) -> COMInterfaceID {
    .init(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)
}