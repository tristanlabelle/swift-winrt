import WindowsRuntime_ABI
import struct Foundation.UUID

public typealias IErrorInfo = any IErrorInfoProtocol
public protocol IErrorInfoProtocol: IUnknownProtocol {
    var guid: Foundation.UUID { get throws }
    var source: String? { get throws }
    var description: String? { get throws }
    var helpFile: String? { get throws }
    var helpContext: UInt32 { get throws }
}

public enum IErrorInfoProjection: COMTwoWayProjection {
    public typealias SwiftObject = IErrorInfo
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IErrorInfo

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IErrorInfoProjection>, IErrorInfoProtocol {
        public var guid: Foundation.UUID { get throws { try _interop.getGuid() } }
        public var source: String? { get throws { try _interop.getSource() } }
        public var description: String? { get throws { try _interop.getDescription() } }
        public var helpFile: String? { get throws { try _interop.getHelpFile() } }
        public var helpContext: UInt32 { get throws { try _interop.getHelpContext() } }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IErrorInfoVTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetGUID: { this, pguid in _implement(this) { try _set(pguid, GUIDProjection.toABI($0.guid)) } },
        GetSource: { this, source in _implement(this) { try _set(source, BStrProjection.toABI($0.source)) } },
        GetDescription: { this, description in _implement(this) { try _set(description, BStrProjection.toABI($0.description)) } },
        GetHelpFile: { this, helpFile in _implement(this) { try _set(helpFile, BStrProjection.toABI($0.helpFile)) } },
        GetHelpContext: { this, helpContext in _implement(this) { try _set(helpContext, $0.helpContext) } })
}

extension WindowsRuntime_ABI.SWRT_IErrorInfo: /* @retroactive */ COMIUnknownStruct {
    public static let iid = COMInterfaceID(0x1CF2B120, 0x547D, 0x101B, 0x8E65, 0x08002B2BD119)
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IErrorInfo {
    public func getGuid() throws -> Foundation.UUID {
        var value = GUIDProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetGUID(this, &value))
        return GUIDProjection.toSwift(value)
    }

    public func getSource() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetSource(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getDescription() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetDescription(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getHelpFile() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetHelpFile(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getHelpContext() throws ->  UInt32 {
        var value = UInt32()
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetHelpContext(this, &value))
        return value
    }
}
