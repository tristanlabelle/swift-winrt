import COM_ABI

public typealias ICreateErrorInfo = any ICreateErrorInfoProtocol
public protocol ICreateErrorInfoProtocol: IUnknownProtocol {
    func setGUID(_ guid: GUID) throws
    func setSource(_ source: String?) throws
    func setDescription(_ description: String?) throws
    func setHelpFile(_ helpFile: String?) throws
    func setHelpContext(_ helpContext: UInt32) throws
}

public enum ICreateErrorInfoProjection: COMTwoWayProjection {
    public typealias ABIStruct = COM_ABI.SWRT_ICreateErrorInfo
    public typealias SwiftObject = ICreateErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ICreateErrorInfoProjection>, ICreateErrorInfoProtocol {
        public func setGUID(_ guid: GUID) throws { try _interop.setGUID(guid) }
        public func setSource(_ source: String?) throws { try _interop.setSource(source) }
        public func setDescription(_ description: String?) throws { try _interop.setDescription(description) }
        public func setHelpFile(_ helpFile: String?) throws { try _interop.setHelpFile(helpFile) }
        public func setHelpContext(_ helpContext: UInt32) throws { try _interop.setHelpContext(helpContext) }
    }

    private static var virtualTable: COM_ABI.SWRT_ICreateErrorInfo_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        SetGUID: { this, guid in _implement(this) {
            guard let guid else { throw COMError.invalidArg }
            try $0.setGUID(GUIDProjection.toSwift(guid.pointee))
        } },
        SetSource: { this, source in _implement(this) { try $0.setSource(BStrProjection.toSwift(source)) } },
        SetDescription: { this, description in _implement(this) { try $0.setDescription(BStrProjection.toSwift(description)) } },
        SetHelpFile: { this, helpFile in _implement(this) { try $0.setHelpFile(BStrProjection.toSwift(helpFile)) } },
        SetHelpContext: { this, helpContext in _implement(this) { try $0.setHelpContext(helpContext) } })
}

public func uuidof(_: COM_ABI.SWRT_ICreateErrorInfo.Type) -> COMInterfaceID {
    .init(0x22F03340, 0x547D, 0x101B, 0x8E65, 0x08002B2BD119)
}

extension COMInterop where ABIStruct == COM_ABI.SWRT_ICreateErrorInfo {
    public func setGUID(_ guid: GUID) throws {
        var guid = GUIDProjection.toABI(guid)
        try COMError.fromABI(this.pointee.VirtualTable.pointee.SetGUID(this, &guid))
    }

    public func setSource(_ source: String?) throws {
        var source = try BStrProjection.toABI(source)
        defer { BStrProjection.release(&source) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.SetSource(this, source))
    }

    public func setDescription(_ description: String?) throws {
        var description = try BStrProjection.toABI(description)
        defer { BStrProjection.release(&description) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.SetDescription(this, description))
    }

    public func setHelpFile(_ helpFile: String?) throws {
        var helpFile = try BStrProjection.toABI(helpFile)
        defer { BStrProjection.release(&helpFile) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.SetHelpFile(this, helpFile))
    }

    public func setHelpContext(_ helpContext: UInt32) throws {
        try COMError.fromABI(this.pointee.VirtualTable.pointee.SetHelpContext(this, helpContext))
    }
}
