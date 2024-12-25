import COM_ABI

public typealias ISupportErrorInfo = any ISupportErrorInfoProtocol
public protocol ISupportErrorInfoProtocol: IUnknownProtocol {
    func interfaceSupportsErrorInfo(_ riid: COMInterfaceID) throws
}

public enum ISupportErrorInfoBinding: COMTwoWayBinding {
    public typealias SwiftObject = ISupportErrorInfo
    public typealias ABIStruct = COM_ABI.SWRT_ISupportErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<ISupportErrorInfoBinding>, ISupportErrorInfoProtocol {
        public func interfaceSupportsErrorInfo(_ riid: COMInterfaceID) throws { try _interop.interfaceSupportsErrorInfo(riid) }
    }

    private static var virtualTable: COM_ABI.SWRT_ISupportErrorInfo_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        InterfaceSupportsErrorInfo: { this, riid in _implement(this) {
            guard let riid else { throw COMError.invalidArg }
            let riid_swift = GUIDBinding.fromABI(riid.pointee)
            try $0.guid.interfaceSupportsErrorInfo(riid_swift)
        } })
}

public func uuidof(_: COM_ABI.SWRT_ISupportErrorInfo.Type) -> COMInterfaceID {
    .init(0xDF0B3D60, 0x548F, 0x101B, 0x8E65, 0x08002B2BD119)
}

extension COMInterop where ABIStruct == COM_ABI.SWRT_ISupportErrorInfo {
    public func interfaceSupportsErrorInfo(_ riid: COMInterfaceID) throws {
        var riid_abi = GUIDBinding.toABI(riid)
        try COMError.fromABI(this.pointee.VirtualTable.pointee.InterfaceSupportsErrorInfo(this, &riid_abi))
    }
}
