import WindowsRuntime_ABI

/// Extends COM IUnknown-derived struct definitions with an interface ID.
/// All conformances will be @retroactive, so this shouldn't be used for dynamic casts.
public protocol COMIUnknownStruct {
    // Conceptually, we should have this member:
    // static var iid: COMInterfaceID { get }
    //
    // However this won't work because generic specializations don't belong
    // to any single module, so we'd run into retroactive conformance issues,
    // where multiple modules are defining the iid.
}

/// Wraps a COM interface pointer and exposes projected versions of its methods.
/// This struct is extended with methods for each COM interface it wraps.
public struct COMInterop<Interface> where Interface: COMIUnknownStruct {
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

    private var unknown: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_IUnknown>{
        this.withMemoryRebound(to: WindowsRuntime_ABI.SWRT_IUnknown.self, capacity: 1) { $0 }
    }

    @discardableResult
    public func addRef() -> UInt32 {
        unknown.pointee.lpVtbl.pointee.AddRef(unknown)
    }

    @discardableResult
    public func release() -> UInt32 {
        unknown.pointee.lpVtbl.pointee.Release(unknown)
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        var iid = GUIDProjection.toABI(id)
        var rawPointer: UnsafeMutableRawPointer? = nil
        try HResult.throwIfFailed(unknown.pointee.lpVtbl.pointee.QueryInterface(unknown, &iid, &rawPointer))
        guard let rawPointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw HResult.Error.noInterface
        }

        let pointer = rawPointer.bindMemory(to: WindowsRuntime_ABI.SWRT_IUnknown.self, capacity: 1)
        return COMReference(transferringRef: pointer)
    }
}
