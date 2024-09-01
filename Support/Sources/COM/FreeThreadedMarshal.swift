import COM_ABI

/// Provides an implementation of IMarshal based on the COM free-threaded marshaler.
internal class FreeThreadedMarshal: COMSecondaryExport<FreeThreadedMarshalProjection> {
    private let marshaler: COMReference<SWRT_IMarshal>

    public init(_ identity: IUnknown) throws {
        var marshalerUnknown: IUnknownPointer? = nil
        try COMError.fromABI(SWRT_CoCreateFreeThreadedMarshaler(/* pUnkOuter: */ nil, &marshalerUnknown))
        guard let marshalerUnknown else { throw COMError.noInterface }
        self.marshaler = COMReference(transferringRef: marshalerUnknown).cast()
        super.init(identity: identity)
    }

    func getUnmarshalClass(_ riid: UnsafeMutablePointer<SWRT_Guid>?, _ pv: UnsafeMutableRawPointer?, _ dwDestContext: UInt32, _ pvDestContext: UnsafeMutableRawPointer?, _ mshlflags: UInt32, _ pCid: UnsafeMutablePointer<SWRT_Guid>?) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.GetUnmarshalClass(
            marshaler.pointer, riid, pv, dwDestContext, pvDestContext, mshlflags, pCid))
    }
    func getMarshalSizeMax(_ riid: UnsafeMutablePointer<SWRT_Guid>?, _ pv: UnsafeMutableRawPointer?, _ dwDestContext: UInt32, _ pvDestContext: UnsafeMutableRawPointer?, _ mshlflags: UInt32, _ pSize: UnsafeMutablePointer<UInt32>?) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.GetMarshalSizeMax(
            marshaler.pointer, riid, pv, dwDestContext, pvDestContext, mshlflags, pSize))
    }
    func marshalInterface(_ pStm: OpaquePointer?, _ riid: UnsafeMutablePointer<SWRT_Guid>?, _ pv: UnsafeMutableRawPointer?, _ dwDestContext: UInt32, _ pvDestContext: UnsafeMutableRawPointer?, _ mshlflags: UInt32) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.MarshalInterface(
            marshaler.pointer, pStm, riid, pv, dwDestContext, pvDestContext, mshlflags))
    }
    func unmarshalInterface(_ pStm: OpaquePointer?, _ riid: UnsafeMutablePointer<SWRT_Guid>?, _ pv: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.UnmarshalInterface(
            marshaler.pointer, pStm, riid, pv))
    }
    func releaseMarshalData(_ pStm: OpaquePointer?) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.ReleaseMarshalData(
            marshaler.pointer, pStm))
    }
    func disconnectObject(_ dwReserved: UInt32) throws {
        try COMError.fromABI(marshaler.pointer.pointee.VirtualTable.pointee.DisconnectObject(
            marshaler.pointer, dwReserved))
    }
}

internal func uuidof(_: COM_ABI.SWRT_IMarshal.Type) -> COMInterfaceID {
    .init(0x00000003, 0x0000, 0x0000, 0xC000, 0x000000000046)
}

internal enum FreeThreadedMarshalProjection: COMTwoWayProjection {
    public typealias SwiftObject = FreeThreadedMarshal
    public typealias ABIStruct = COM_ABI.SWRT_IMarshal

    public static var interfaceID: COMInterfaceID { uuidof(ABIStruct.self) }
    public static var virtualTablePointer: UnsafeRawPointer { .init(withUnsafePointer(to: &virtualTable) { $0 }) }

    public static func _wrap(_ reference: consuming ABIReference) -> SwiftObject {
        fatalError("Not implemented")
    }

    public static func toCOM(_ object: SwiftObject) throws -> ABIReference {
        fatalError("Not implemented")
    }

    private static var virtualTable: COM_ABI.SWRT_IMarshal_VirtualTable = .init(
        QueryInterface: { IUnknownVirtualTable.QueryInterface($0, $1, $2) },
        AddRef: { IUnknownVirtualTable.AddRef($0) },
        Release: { IUnknownVirtualTable.Release($0) },
        GetUnmarshalClass: { this, riid, pv, dwDestContext, pvDestContext, mshlflags, pCid in _implement(this) { this in
            try this.getUnmarshalClass(riid, pv, dwDestContext, pvDestContext, mshlflags, pCid)
        } },
        GetMarshalSizeMax: { this, riid, pv, dwDestContext, pvDestContext, mshlflags, pSize in _implement(this) { this in
            try this.getMarshalSizeMax(riid, pv, dwDestContext, pvDestContext, mshlflags, pSize)
        } },
        MarshalInterface: { this, pStm, riid, pv, dwDestContext, pvDestContext, mshlflags in _implement(this) { this in
            try this.marshalInterface(pStm, riid, pv, dwDestContext, pvDestContext, mshlflags)
        } },
        UnmarshalInterface: { this, pStm, riid, pv in _implement(this) { this in
            try this.unmarshalInterface(pStm, riid, pv)
        } },
        ReleaseMarshalData: { this, pStm in _implement(this) { this in
            try this.releaseMarshalData(pStm)
        } },
        DisconnectObject: { this, dwReserved in _implement(this) { this in
            try this.disconnectObject(dwReserved)
        } })
}