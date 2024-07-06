/// Provides a way to represent the current object as a string.
public typealias WindowsFoundation_IStringable = any WindowsFoundation_IStringableProtocol

/// Provides a way to represent the current object as a string.
public protocol WindowsFoundation_IStringableProtocol: IInspectableProtocol {
    /// Gets a string that represents the current object.
    func toString() throws -> String
}

import WindowsRuntime_ABI

public enum WindowsFoundation_IStringableProjection: InterfaceProjection {
    public typealias SwiftObject = WindowsFoundation_IStringable
    public typealias COMInterface = SWRT_WindowsFoundation_IStringable

    public static var typeName: String { "Windows.Foundation.IStringable" }
    public static var interfaceID: COMInterfaceID { uuidof(COMInterface.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: WinRTImport<WindowsFoundation_IStringableProjection>, WindowsFoundation_IStringableProtocol {
        public func toString() throws -> String {
            try _interop.toString()
        }
    }

    private static var virtualTable: SWRT_WindowsFoundation_IStringable_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetIids: { IInspectableVirtualTable.GetIids($0, $1, $2) },
        GetRuntimeClassName: { IInspectableVirtualTable.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { IInspectableVirtualTable.GetTrustLevel($0, $1) },
        ToString: { this, value in _implement(this) { try _set(value, PrimitiveProjection.String.toABI($0.toString())) } })
}

#if swift(>=6)
extension SWRT_WindowsFoundation_IStringable: @retroactive COMIUnknownStruct {}
#endif

extension SWRT_WindowsFoundation_IStringable: /* @retroactive */ COMIInspectableStruct {}

public func uuidof(_: WindowsRuntime_ABI.SWRT_WindowsFoundation_IStringable.Type) -> COMInterfaceID {
    .init(0x96369F54, 0x8EB6, 0x48F0, 0xABCE, 0xC1B211E627C3);
}

extension COMInterop where Interface == SWRT_WindowsFoundation_IStringable {
    public func toString() throws -> String {
        var value = PrimitiveProjection.String.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.ToString(this, &value))
        return PrimitiveProjection.String.toSwift(consuming: &value)
    }
}