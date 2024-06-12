import COM
import WindowsRuntime_ABI

public typealias IInspectable = any IInspectableProtocol
public protocol IInspectableProtocol: IUnknownProtocol {
    func getIids() throws -> [COMInterfaceID]
    func getRuntimeClassName() throws -> String
    func getTrustLevel() throws -> TrustLevel
}

public enum IInspectableProjection: InterfaceProjection {
    public typealias SwiftObject = IInspectable
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IInspectable

    public static var typeName: String { "IInspectable" }
    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IInspectableProjection> {}

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IInspectable_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
        GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) })
}

/// Identifies COM interface structs as deriving from IInspectable.
/// Do not use for dynamic casting because conformances will be @retroactive.
public protocol COMIInspectableStruct: COMIUnknownStruct {}

#if swift(>=6)
extension WindowsRuntime_ABI.SWRT_IInspectable: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IInspectable: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
}

public typealias IInspectablePointer = IInspectableProjection.COMPointer
public typealias IInspectableReference = COMReference<IInspectableProjection.COMInterface>

// Ideally this would be "where Interface: COMIInspectableStruct", but we run into compiler bugs
extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IInspectable {
    public func getIids() throws -> [COMInterfaceID] {
        var iids: COMArray<WindowsRuntime_ABI.SWRT_Guid> = .null
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.GetIids(this, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return ArrayProjection<GUIDProjection>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        var runtimeClassName: WindowsRuntime_ABI.SWRT_HString?
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.GetRuntimeClassName(this, &runtimeClassName))
        return PrimitiveProjection.String.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        var trustLevel: WindowsRuntime_ABI.SWRT_TrustLevel = 0
        try WinRTError.throwIfFailed(this.pointee.VirtualTable.pointee.GetTrustLevel(this, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}