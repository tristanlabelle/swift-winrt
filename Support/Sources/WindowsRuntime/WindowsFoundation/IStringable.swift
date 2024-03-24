import WindowsRuntime_ABI

public typealias WindowsFoundation_IStringable = any WindowsFoundation_IStringableProtocol
public protocol WindowsFoundation_IStringableProtocol: IInspectableProtocol {
    func toString() throws -> String
}

public enum WindowsFoundation_IStringableProjection: WinRTTwoWayProjection {
    public typealias SwiftObject = WindowsFoundation_IStringable
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringable
    public typealias COMVirtualTable = WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringableVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var runtimeClassName: String { "Windows.Foundation.IStringable" }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<WindowsFoundation_IStringableProjection>, WindowsFoundation_IStringableProtocol {
        public func toString() throws -> String {
            try _interop.toString()
        }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
        GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) },
        ToString: { this, value in _getter(this, value) { this in try HStringProjection.toABI(this.toString()) } })
}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringable: @retroactive COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringable: /* @retroactive */ COMIInspectableStruct {
    public static let iid = COMInterfaceID(0x96369F54, 0x8EB6, 0x48F0, 0xABCE, 0xC1B211E627C3);
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringable {
    public func toString() throws -> String {
        var value = HStringProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.ToString(this, &value))
        return HStringProjection.toSwift(consuming: &value)
    }
}