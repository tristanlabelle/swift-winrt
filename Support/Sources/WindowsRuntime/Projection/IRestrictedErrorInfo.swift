import COM

public typealias IRestrictedErrorInfo = any IRestrictedErrorInfoProtocol
public protocol IRestrictedErrorInfoProtocol: IUnknownProtocol {
    func getErrorDetails(
        _ description: inout String?,
        _ error: inout HResult,
        _ restrictedDescription: inout String?,
        _ capabilitySid: inout String?) throws
    var reference: String? { get throws }
}

extension IRestrictedErrorInfoProtocol {
    var errorDetails: (description: String?, error: HResult, restrictedDescription: String?, capabilitySid: String?) {
        get throws {
            var description: String? = nil
            var error: HResult = .fail
            var restrictedDescription: String? = nil
            var capabilitySid: String? = nil
            try getErrorDetails(&description, &error, &restrictedDescription, &capabilitySid)
            return (description, error, restrictedDescription, capabilitySid)
        }
    }
}

import WindowsRuntime_ABI

public enum IRestrictedErrorInfoBinding: COMBinding {
    public typealias SwiftObject = IRestrictedErrorInfo
    public typealias ABIStruct = WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        Import(_wrapping: reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IRestrictedErrorInfoBinding>, IRestrictedErrorInfoProtocol {
        func getErrorDetails(
                _ description: inout String?,
                _ error: inout HResult,
                _ restrictedDescription: inout String?,
                _ capabilitySid: inout String?) throws {
            try _interop.getErrorDetails(&description, &error, &restrictedDescription, &capabilitySid)
        }

        public var reference: String? { get throws { try _interop.getReference() } }
    }
}

public func uuidof(_: WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo.Type) -> COMInterfaceID {
    .init(0x82BA7092, 0x4C88, 0x427D, 0xA7BC, 0x16DD93FEB67E)
}

extension COMInterop where ABIStruct == WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo {
    public func getErrorDetails(
            _ description: inout String?,
            _ error: inout HResult,
            _ restrictedDescription: inout String?,
            _ capabilitySid: inout String?) throws {
        var description_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrBinding.release(&description_) }
        var error_: WindowsRuntime_ABI.SWRT_HResult = 0
        var restrictedDescription_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrBinding.release(&restrictedDescription_) }
        var capabilitySid_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrBinding.release(&capabilitySid_) }
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetErrorDetails(this, &description_, &error_, &restrictedDescription_, &capabilitySid_))
        description = BStrBinding.fromABI(consuming: &description_)
        error = HResultBinding.fromABI(error_)
        restrictedDescription = BStrBinding.fromABI(consuming: &restrictedDescription_)
        capabilitySid = BStrBinding.fromABI(consuming: &capabilitySid_)
    }

    public func getReference() throws -> String? {
        var value = BStrBinding.abiDefaultValue
        try COMError.fromABI(this.pointee.VirtualTable.pointee.GetReference(this, &value))
        return BStrBinding.fromABI(consuming: &value)
    }
}