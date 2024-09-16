import COM

public typealias IInspectable = any IInspectableProtocol
public protocol IInspectableProtocol: IUnknownProtocol {
    func getIids() throws -> [COMInterfaceID]
    func getRuntimeClassName() throws -> String
    func getTrustLevel() throws -> TrustLevel
}

import WindowsRuntime_ABI

public enum IInspectableBinding: InterfaceBinding {
    public typealias SwiftObject = IInspectable
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IInspectable

    public static var typeName: String { "IInspectable" }
    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<IInspectableBinding> {}

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IInspectable_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
        GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) })
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IInspectable.Type) -> COMInterfaceID {
    .init(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
}

public typealias IInspectablePointer = IInspectableBinding.ABIPointer
public typealias IInspectableReference = IInspectableBinding.ABIReference

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IInspectable {
    public func getIids() throws -> [COMInterfaceID] {
        var iids: COMArray<WindowsRuntime_ABI.SWRT_Guid> = .null
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.GetIids(this, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return ArrayBinding<GUIDBinding>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        var runtimeClassName: WindowsRuntime_ABI.SWRT_HString?
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.GetRuntimeClassName(this, &runtimeClassName))
        return StringBinding.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        var trustLevel: WindowsRuntime_ABI.SWRT_TrustLevel = 0
        try WinRTError.fromABI(this.pointee.VirtualTable.pointee.GetTrustLevel(this, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}