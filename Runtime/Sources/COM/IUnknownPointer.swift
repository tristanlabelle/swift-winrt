import CWinRTCore

public typealias IUnknownPointer = UnsafeMutablePointer<CWinRTCore.IUnknown>

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

    public func queryInterface<Interface>(_ iid: IID, _ type: Interface.Type) throws -> UnsafeMutablePointer<Interface> {
        var iid = iid
        var pointer: UnsafeMutableRawPointer? = nil
        try HResult.throwIfFailed(self.pointee.lpVtbl.pointee.QueryInterface(self, &iid, &pointer))
        guard let pointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw HResult.Error.noInterface
        }

        return pointer.bindMemory(to: Interface.self, capacity: 1)
    }

    public func queryInterface(_ iid: IID) throws -> IUnknownPointer {
        try self.queryInterface(iid, IUnknownPointer.Pointee.self)
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
    public static func release(_ pointer: UnsafeMutableRawPointer) -> UInt32 {
        cast(pointer).release()
    }

    // UnsafeMutablePointer<Interface> helpers
    public static func cast<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> IUnknownPointer {
        pointer.withMemoryRebound(to: IUnknownPointer.Pointee.self, capacity: 1) { $0 }
    }

    @discardableResult
    public static func addRef<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> UInt32 {
        cast(pointer).addRef()
    }

    public static func addingRef<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> UnsafeMutablePointer<Interface> {
        addRef(pointer)
        return pointer
    }

    @discardableResult
    public static func release<Interface>(_ pointer: UnsafeMutablePointer<Interface>) -> UInt32 {
        cast(pointer).release()
    }
}