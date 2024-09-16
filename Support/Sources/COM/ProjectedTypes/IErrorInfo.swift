import COM_ABI

public typealias IErrorInfo = any IErrorInfoProtocol
public protocol IErrorInfoProtocol: IUnknownProtocol {
    var guid: GUID { get throws }
    var source: String? { get throws }
    var description: String? { get throws }
    var helpFile: String? { get throws }
    var helpContext: UInt32 { get throws }
}

public enum IErrorInfoBinding: COMTwoWayBinding {
    public typealias SwiftObject = IErrorInfo
    public typealias ABIStruct = COM_ABI.SWRT_IErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IErrorInfoBinding>, IErrorInfoProtocol {
        public var guid: GUID { get throws { try _interop.getGuid() } }
        public var source: String? { get throws { try _interop.getSource() } }
        public var description: String? { get throws { try _interop.getDescription() } }
        public var helpFile: String? { get throws { try _interop.getHelpFile() } }
        public var helpContext: UInt32 { get throws { try _interop.getHelpContext() } }
    }

    private static var virtualTable: COM_ABI.SWRT_IErrorInfo_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetGUID: { this, pguid in _implement(this) { try _set(pguid, GUIDBinding.toABI($0.guid)) } },
        GetSource: { this, source in _implement(this) { try _set(source, BStrBinding.toABI($0.source)) } },
        GetDescription: { this, description in _implement(this) { try _set(description, BStrBinding.toABI($0.description)) } },
        GetHelpFile: { this, helpFile in _implement(this) { try _set(helpFile, BStrBinding.toABI($0.helpFile)) } },
        GetHelpContext: { this, helpContext in _implement(this) { try _set(helpContext, $0.helpContext) } })
}

public func uuidof(_: COM_ABI.SWRT_IErrorInfo.Type) -> COMInterfaceID {
    .init(0x1CF2B120, 0x547D, 0x101B, 0x8E65, 0x08002B2BD119)
}

extension COMInterop where ABIStruct == COM_ABI.SWRT_IErrorInfo {
    public func getGuid() throws -> GUID {
        var value = GUIDBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetGUID(this, &value))
        return GUIDBinding.toSwift(value)
    }

    public func getSource() throws ->  String? {
        var value = BStrBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetSource(this, &value))
        return BStrBinding.toSwift(consuming: &value)
    }

    public func getDescription() throws ->  String? {
        var value = BStrBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetDescription(this, &value))
        return BStrBinding.toSwift(consuming: &value)
    }

    public func getHelpFile() throws ->  String? {
        var value = BStrBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetHelpFile(this, &value))
        return BStrBinding.toSwift(consuming: &value)
    }

    public func getHelpContext() throws ->  UInt32 {
        var value = UInt32()
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetHelpContext(this, &value))
        return value
    }
}
