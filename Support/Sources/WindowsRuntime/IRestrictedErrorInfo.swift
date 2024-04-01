import WindowsRuntime_ABI
import struct Foundation.UUID

public typealias IRestrictedErrorInfo = any IRestrictedErrorInfoProtocol
public protocol IRestrictedErrorInfoProtocol: IUnknownProtocol {
    func getErrorDetails(
        description: inout String?,
        error: inout HResult,
        restrictedDescription: inout String?,
        capabilitySid: inout String?) throws
    var reference: String? { get throws }
}

public enum IRestrictedErrorInfoProjection: COMTwoWayProjection {
    public typealias SwiftObject = IRestrictedErrorInfo
    public typealias COMInterface = WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo

    public static var interfaceID: COMInterfaceID { COMInterface.iid }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func toSwift(_ reference: consuming COMReference<COMInterface>) -> SwiftObject {
        Import.toSwift(reference)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        try Import.toCOM(object)
    }

    private final class Import: COMImport<IRestrictedErrorInfoProjection>, IRestrictedErrorInfoProtocol {
        func getErrorDetails(
                description: inout String?,
                error: inout HResult,
                restrictedDescription: inout String?,
                capabilitySid: inout String?) throws {
            try _interop.getErrorDetails(&description, &error, &restrictedDescription, &capabilitySid)
        }

        public var reference: String? { get throws { try _interop.getReference() } }
    }

    private static var virtualTable: WindowsRuntime_ABI.SWRT_IRestrictedErrorInfoVTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetErrorDetails: { this, description, error, restrictedDescription, capabilitySid in _implement(this) {
            var description_: String? = nil
            var error_: HResult = .ok
            var restrictedDescription_: String? = nil
            var capabilitySid_: String? = nil
            try $0.getErrorDetails(description: &description_, error: &error_, restrictedDescription: &restrictedDescription_, capabilitySid: &capabilitySid_)
            var _success = false
            if let description { description.pointee = try BStrProjection.toABI(description_) }
            defer { if !_success, let description { BStrProjection.release(&description.pointee) } }
            if let error { error.pointee = HResultProjection.toABI(error_) }
            if let restrictedDescription { restrictedDescription.pointee = try BStrProjection.toABI(restrictedDescription_) }
            defer { if !_success, let restrictedDescription { BStrProjection.release(&restrictedDescription.pointee) } }
            if let capabilitySid { capabilitySid.pointee = try BStrProjection.toABI(capabilitySid_) }
            defer { if !_success, let capabilitySid { BStrProjection.release(&capabilitySid.pointee) } }
            _success = true
        } },
        GetReference: { this, reference in _implement(this) { try _set(reference, BStrProjection.toABI($0.reference)) } })
}

#if swift(>=5.10)
extension WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo: @retroactive COMIUnknownStruct {}
#else
extension WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo: COMIUnknownStruct {}
#endif

extension WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo {
    public static let iid = COMInterfaceID(0x82BA7092, 0x4C88, 0x427D, 0xA7BC, 0x16DD93FEB67E)
}

extension COMInterop where Interface == WindowsRuntime_ABI.SWRT_IRestrictedErrorInfo {
    public func getErrorDetails(
            _ description: inout String?,
            _ error: inout HResult,
            _ restrictedDescription: inout String?,
            _ capabilitySid: inout String?) throws {
        var description_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrProjection.release(&description_) }
        var error_: WindowsRuntime_ABI.SWRT_HResult = 0
        var restrictedDescription_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrProjection.release(&restrictedDescription_) }
        var capabilitySid_: WindowsRuntime_ABI.SWRT_BStr? = nil
        defer { BStrProjection.release(&capabilitySid_) }
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetErrorDetails(this, &description_, &error_, &restrictedDescription_, &capabilitySid_))
        description = BStrProjection.toSwift(consuming: &description_)
        error = HResultProjection.toSwift(error_)
        restrictedDescription = BStrProjection.toSwift(consuming: &restrictedDescription_)
        capabilitySid = BStrProjection.toSwift(consuming: &capabilitySid_)
    }

    public func getReference() throws -> String? {
        var value = BStrProjection.abiDefaultValue
        try HResult.throwIfFailed(this.pointee.VirtualTable.pointee.GetReference(this, &value))
        return BStrProjection.toSwift(consuming: &value)
    }
}