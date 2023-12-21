import CWinRTCore
import struct Foundation.UUID

public protocol IRestrictedErrorInfoProtocol: IUnknownProtocol {
    func getErrorDetails(
        description: inout String?,
        error: inout HResult,
        restrictedDescription: inout String?,
        capabilitySid: inout String?) throws
    var reference: String? { get throws }
}

public typealias IRestrictedErrorInfo = any IRestrictedErrorInfoProtocol

public enum IRestrictedErrorInfoProjection: COMTwoWayProjection {
    public typealias SwiftObject = IRestrictedErrorInfo
    public typealias COMInterface = CWinRTCore.SWRT_IRestrictedErrorInfo
    public typealias COMVirtualTable = CWinRTCore.SWRT_IRestrictedErrorInfoVTable

    public static let id = COMInterfaceID(0x82BA7092, 0x4C88, 0x427D, 0xA7BC, 0x16DD93FEB67E)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, importType: Import.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, importType: Import.self)
    }

    private final class Import: COMImport<IRestrictedErrorInfoProjection>, IRestrictedErrorInfoProtocol {
        func getErrorDetails(
                description: inout String?,
                error: inout HResult,
                restrictedDescription: inout String?,
                capabilitySid: inout String?) throws {
            var description_: CWinRTCore.SWRT_BStr? = nil
            defer { BStrProjection.release(&description_) }
            var error_: CWinRTCore.SWRT_HResult = 0
            var restrictedDescription_: CWinRTCore.SWRT_BStr? = nil
            defer { BStrProjection.release(&restrictedDescription_) }
            var capabilitySid_: CWinRTCore.SWRT_BStr? = nil
            defer { BStrProjection.release(&capabilitySid_) }
            try HResult.throwIfFailed(_vtable.GetErrorDetails(comPointer, &description_, &error_, &restrictedDescription_, &capabilitySid_))
            description = BStrProjection.toSwift(consuming: &description_)
            error = HResultProjection.toSwift(error_)
            restrictedDescription = BStrProjection.toSwift(consuming: &restrictedDescription_)
            capabilitySid = BStrProjection.toSwift(consuming: &capabilitySid_)
        }

        public var reference: String? { get throws { try _getter(_vtable.GetReference, BStrProjection.self) } }
    }

    private static var virtualTable: COMVirtualTable = .init(
        QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
        AddRef: { this in _addRef(this) },
        Release: { this in _release(this) },
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
        GetReference: { this, reference in _getter(this, reference) { try BStrProjection.toABI($0.reference) } })
}