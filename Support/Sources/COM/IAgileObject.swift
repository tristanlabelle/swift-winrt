import WindowsRuntime_ABI

/// Projection for the IAgileObject interface.
/// This is a marker interface which we automatically implement for all COM projections,
/// so we don't need to expose a protocol type for it or a two-way projection.
public enum IAgileObjectProjection: COMProjection {
    public typealias SwiftObject = IUnknown // Avoid introducing an interface for IAgileObject since it is a marker interface.
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IAgileObject
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_IAgileObjectVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        let reference = reference.reinterpret(to: WindowsRuntime_ABI.SWRT_IUnknown.self)
        return IUnknownProjection.toSwift(consume reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try object._queryInterface(Self.self)
    }
}

extension WindowsRuntime_ABI.SWRT_IAgileObject: /* @retroactive */ COMIUnknownStruct {
    public static let iid = COMInterfaceID(0x94EA2B94, 0xE9CC, 0x49E0, 0xC0FF, 0xEE64CA8F5B90)
}