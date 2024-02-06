import CWinRTCore

/// Wraps a COM interface pointer and exposes projected versions of its methods.
/// This struct is extended with methods for each COM interface it wraps.
public struct COMInterop<Interface> {
    public let this: UnsafeMutablePointer<Interface>

    public init(_ pointer: UnsafeMutablePointer<Interface>) {
        self.this = pointer
    }

    public init<Other>(casting pointer: UnsafeMutablePointer<Other>) {
        self.init(pointer.withMemoryRebound(to: Interface.self, capacity: 1) { $0 })
    }

    public init<Other>(casting other: COMInterop<Other>) {
        self.init(casting: other.this)
    }

    private var unknown: UnsafeMutablePointer<CWinRTCore.SWRT_IUnknown>{
        this.withMemoryRebound(to: CWinRTCore.SWRT_IUnknown.self, capacity: 1) { $0 }
    }

    @discardableResult
    public func addRef() -> UInt32 {
        unknown.pointee.lpVtbl.pointee.AddRef(unknown)
    }

    @discardableResult
    public func release() -> UInt32 {
        unknown.pointee.lpVtbl.pointee.Release(unknown)
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownPointer {
        var iid = GUIDProjection.toABI(id)
        var pointer: UnsafeMutableRawPointer? = nil
        try HResult.throwIfFailed(unknown.pointee.lpVtbl.pointee.QueryInterface(unknown, &iid, &pointer))
        guard let pointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw HResult.Error.noInterface
        }

        return pointer.bindMemory(to: CWinRTCore.SWRT_IUnknown.self, capacity: 1)
    }
}