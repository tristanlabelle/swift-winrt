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

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IInspectableVTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
        GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) })
}

/// Identifies COM interface structs as deriving from IInspectable.
/// Do not use for dynamic casting because conformances will be @retroactive.
public protocol COMIInspectableStruct: COMIUnknownStruct {}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IInspectable: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IInspectable: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
}

public typealias IInspectablePointer = IInspectableProjection.COMPointer
public typealias IInspectableReference = COMReference<IInspectableProjection.COMInterface>

extension COMInterop where Interface: /* @retroactive */ COMIInspectableStruct {
    private var inspectable: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_IInspectable>{
        this.withMemoryRebound(to: WindowsRuntime_ABI.SWRT_IInspectable.self, capacity: 1) { $0 }
    }

    public func getIids() throws -> [COMInterfaceID] {
        var iids: COMArray<WindowsRuntime_ABI.SWRT_Guid> = .null
        try WinRTError.throwIfFailed(inspectable.pointee.VirtualTable.pointee.GetIids(inspectable, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return ArrayProjection<GUIDProjection>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        var runtimeClassName: WindowsRuntime_ABI.SWRT_HString?
        try WinRTError.throwIfFailed(inspectable.pointee.VirtualTable.pointee.GetRuntimeClassName(inspectable, &runtimeClassName))
        return PrimitiveProjection.String.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        var trustLevel: WindowsRuntime_ABI.SWRT_TrustLevel = 0
        try WinRTError.throwIfFailed(inspectable.pointee.VirtualTable.pointee.GetTrustLevel(inspectable, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}