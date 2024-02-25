import CWinRTCore
import struct Foundation.UUID

public protocol IErrorInfoProtocol: IUnknownProtocol {
    var guid: Foundation.UUID { get throws }
    var source: String? { get throws }
    var description: String? { get throws }
    var helpFile: String? { get throws }
    var helpContext: UInt32 { get throws }
}

public typealias IErrorInfo = any IErrorInfoProtocol

public enum IErrorInfoProjection: COMTwoWayProjection {
    public typealias SwiftObject = IErrorInfo
    public typealias COMInterface = CWinRTCore.SWRT_IErrorInfo
    public typealias COMVirtualTable = CWinRTCore.SWRT_IErrorInfoVTable

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        Import.toSwift(transferringRef: comPointer)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IErrorInfoProjection>, IErrorInfoProtocol {
        public var guid: Foundation.UUID { get throws { try _interop.getGuid() } }
        public var source: String? { get throws { try _interop.getSource() } }
        public var description: String? { get throws { try _interop.getDescription() } }
        public var helpFile: String? { get throws { try _interop.getHelpFile() } }
        public var helpContext: UInt32 { get throws { try _interop.getHelpContext() } }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetGUID: { this, pguid in _getter(this, pguid) { try GUIDProjection.toABI($0.guid) } },
        GetSource: { this, source in _getter(this, source) { try BStrProjection.toABI($0.source) } },
        GetDescription: { this, description in _getter(this, description) { try BStrProjection.toABI($0.description) } },
        GetHelpFile: { this, helpFile in _getter(this, helpFile) { try BStrProjection.toABI($0.helpFile) } },
        GetHelpContext: { this, helpContext in _getter(this, helpContext) { try $0.helpContext } })
}

extension CWinRTCore.SWRT_IErrorInfo: /* @retroactive */ COMIUnknownStruct {
    public static let iid = COMInterfaceID(0x1CF2B120, 0x547D, 0x101B, 0x8E65, 0x08002B2BD119)
}

extension COMInterop where Interface == CWinRTCore.SWRT_IErrorInfo {
    public func getGuid() throws -> Foundation.UUID {
        var value = GUIDProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetGUID(this, &value))
        return GUIDProjection.toSwift(value)
    }

    public func getSource() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetSource(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getDescription() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetDescription(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getHelpFile() throws ->  String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetHelpFile(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }

    public func getHelpContext() throws ->  UInt32 {
        var value = UInt32()
        try HResult.throwIfFailed(this.pointee.lpVtbl.pointee.GetHelpContext(this, &value))
        return value
    }
}
