import CWinRTCore

/// Projection for the IAgileObject interface.
/// This is a marker interface which we automatically implement for all COM projections,
/// so we don't need to expose a protocol type for it or a two-way projection.
public enum IAgileObjectProjection: COMProjection {
    public typealias SwiftObject = IUnknown // Avoid introducing an interface for IAgileObject since it is a marker interface.
    public typealias COMInterface = CWinRTCore.SWRT_IAgileObject
    public typealias COMVirtualTable = CWinRTCore.SWRT_IAgileObjectVTable

    public static let id = COMInterfaceID(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        IUnknownProjection.toSwift(transferringRef: IUnknownPointer.cast(comPointer))
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try object._queryInterfacePointer(Self.self)
    }
}