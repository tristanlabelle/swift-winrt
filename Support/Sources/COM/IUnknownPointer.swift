import WindowsRuntime_ABI

public typealias IUnknownPointer = UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_IUnknown>

extension IUnknownPointer {
    @discardableResult
    public func addRef() -> UInt32 {
        self.pointee.lpVtbl.pointee.AddRef(self)
    }

    public func addingRef() -> IUnknownPointer {
        self.addRef()
        return self
    }

    @discardableResult
    public func release() -> UInt32 {
        self.pointee.lpVtbl.pointee.Release(self)
    }

    public var _unsafeRefCount: UInt32 {
        let postAddRef = addRef()
        let postRelease = release()
        assert(postRelease + 1 == postAddRef,
            "Unexpected ref count change during _unsafeRefCount")
        return postRelease
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownPointer {
        var iid = GUIDProjection.toABI(id)
        var pointer: UnsafeMutableRawPointer? = nil
        try HResult.throwIfFailed(self.pointee.lpVtbl.pointee.QueryInterface(self, &iid, &pointer))
        guard let pointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw HResult.Error.noInterface
        }

        return pointer.bindMemory(to: WindowsRuntime_ABI.SWRT_IUnknown.self, capacity: 1)
    }

    public func queryInterface<Projection: COMProjection>(_: Projection.Type) throws -> Projection.COMPointer {
        try queryInterface(Projection.interfaceID).cast(to: Projection.COMInterface.self)
    }

    public func cast<COMInterface>(to type: COMInterface.Type = COMInterface.self) -> UnsafeMutablePointer<COMInterface> {
        self.withMemoryRebound(to: COMInterface.self, capacity: 1) { $0 }
    }

    // UnsafeMutableRawPointer helpers
    public static func cast(_ pointer: UnsafeMutableRawPointer) -> IUnknownPointer {
        pointer.bindMemory(to: IUnknownPointer.Pointee.self, capacity: 1)
    }

    @discardableResult
    public static func addRef(_ pointer: UnsafeMutableRawPointer) -> UInt32 {
        cast(pointer).addRef()
    }

    public static func addingRef(_ pointer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
        addRef(pointer)
        return pointer
    }

    @discardableResult
    public static func release(_ pointer: UnsafeMutableRawPointer?) -> UInt32 {
        guard let pointer else { return 0 }
        return cast(pointer).release()
    }

    // UnsafeMutablePointer<Interface> helpers
    public static func cast<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> IUnknownPointer {
        pointer.withMemoryRebound(to: IUnknownPointer.Pointee.self, capacity: 1) { $0 }
    }

    @discardableResult
    public static func addRef<Interface>(_ this: UnsafeMutablePointer<Interface>) -> UInt32 {
        cast(this).addRef()
    }

    public static func addingRef<Interface>(_ this: UnsafeMutablePointer<Interface>) -> UnsafeMutablePointer<Interface> {
        addRef(this)
        return this
    }

    @discardableResult
    public static func release<Interface>(_ this: UnsafeMutablePointer<Interface>?) -> UInt32 {
        guard let this else { return 0 }
        return cast(this).release()
    }

    public static func queryInterface<Interface, Projection: COMProjection>(_ this: UnsafeMutablePointer<Interface>, _: Projection.Type) throws -> Projection.COMPointer {
        try cast(this).queryInterface(Projection.self)
    }

    public static func queryInterface<Interface>(_ this: UnsafeMutablePointer<Interface>, _ id: COMInterfaceID) throws -> IUnknownPointer {
        try cast(this).queryInterface(id)
    }
}