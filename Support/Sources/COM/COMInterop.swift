import COM_ABI

/// Wraps a COM interface pointer and exposes projected versions of its methods.
/// This struct is extended with methods for each COM interface it wraps.
public struct COMInterop<ABIStruct> {
    public let this: UnsafeMutablePointer<ABIStruct>

    public init(_ pointer: UnsafeMutablePointer<ABIStruct>) {
        self.this = pointer
    }

    public init<Other>(casting pointer: UnsafeMutablePointer<Other>) {
        self.init(pointer.withMemoryRebound(to: ABIStruct.self, capacity: 1) { $0 })
    }

    public init<Other>(casting other: COMInterop<Other>) {
        self.init(casting: other.this)
    }

    private var unknown: UnsafeMutablePointer<COM_ABI.SWRT_IUnknown>{
        this.withMemoryRebound(to: COM_ABI.SWRT_IUnknown.self, capacity: 1) { $0 }
    }

    @discardableResult
    public func addRef() -> UInt32 {
        unknown.pointee.VirtualTable.pointee.AddRef(unknown)
    }

    @discardableResult
    public func release() -> UInt32 {
        unknown.pointee.VirtualTable.pointee.Release(unknown)
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        var iid = GUIDProjection.toABI(id)
        var rawPointer: UnsafeMutableRawPointer? = nil
        // Avoid calling GetErrorInfo since RoOriginateError causes QueryInterface calls
        try COMError.fromABI(captureErrorInfo: false, unknown.pointee.VirtualTable.pointee.QueryInterface(unknown, &iid, &rawPointer))
        guard let rawPointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw COMError.noInterface
        }

        let pointer = rawPointer.bindMemory(to: COM_ABI.SWRT_IUnknown.self, capacity: 1)
        return COMReference(transferringRef: pointer)
    }

    public func queryInterface<OtherABIStruct>(
            _ id: COMInterfaceID, type: OtherABIStruct.Type = OtherABIStruct.self) throws -> COMReference<OtherABIStruct> {
        (try queryInterface(id) as IUnknownReference).cast(to: type)
    }
}
