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

    public static let id = COMInterfaceID(0x1CF2B120, 0x547D, 0x101B, 0x8E65, 0x08002B2BD119)
    public static var virtualTablePointer: COMVirtualTablePointer { withUnsafePointer(to: &Implementation.virtualTable) { $0 } }

    public static func toSwift(transferringRef comPointer: COMPointer) -> SwiftObject {
        toSwift(transferringRef: comPointer, implementation: Implementation.self)
    }

    public static func toCOM(_ object: SwiftObject) throws -> COMPointer {
        try toCOM(object, implementation: Implementation.self)
    }

    private final class Implementation: COMImport<IErrorInfoProjection>, IErrorInfoProtocol {
        public var guid: Foundation.UUID { get throws { try _getter(_vtable.GetGUID, GUIDProjection.self) } }
        public var source: String? { get throws { try _getter(_vtable.GetSource, BStrProjection.self) } }
        public var description: String? { get throws { try _getter(_vtable.GetDescription, BStrProjection.self) } }
        public var helpFile: String? { get throws { try _getter(_vtable.GetHelpFile, BStrProjection.self) } }
        public var helpContext: UInt32 { get throws { try _getter(_vtable.GetHelpContext) } }

        public static var virtualTable: COMVirtualTable = .init(
            QueryInterface: { this, iid, ppvObject in _queryInterface(this, iid, ppvObject) },
            AddRef: { this in _addRef(this) },
            Release: { this in _release(this) },
            GetGUID: { this, pguid in _getter(this, pguid) { try GUIDProjection.toABI($0.guid) } },
            GetSource: { this, source in _getter(this, source) { try BStrProjection.toABI($0.source) } },
            GetDescription: { this, description in _getter(this, description) { try BStrProjection.toABI($0.description) } },
            GetHelpFile: { this, helpFile in _getter(this, helpFile) { try BStrProjection.toABI($0.helpFile) } },
            GetHelpContext: { this, helpContext in _getter(this, helpContext) { try $0.helpContext } }
        )
    }
}