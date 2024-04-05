import WindowsRuntime_ABI

/// Holds a strong reference to a COM object, like a C++ smart pointer.
// Should require COMIUnknownStruct but we run into compiler bugs.
public struct COMReference<Interface>: ~Copyable /* where Interface: COMIUnknownStruct */ {
    public var pointer: UnsafeMutablePointer<Interface>

    public init(transferringRef pointer: UnsafeMutablePointer<Interface>) {
        self.pointer = pointer
    }

    public init(addingRef pointer: UnsafeMutablePointer<Interface>) {
        self.init(transferringRef: pointer)
        interop.addRef()
    }

    public var interop: COMInterop<Interface> { .init(pointer) }

    public func clone() -> COMReference<Interface> { .init(addingRef: pointer) }

    public consuming func detach() -> UnsafeMutablePointer<Interface> {
        let pointer = self.pointer
        discard self
        return pointer
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        try interop.queryInterface(id)
    }

    public func queryInterface<Other>(_ id: COMInterfaceID, type: Other.Type = Other.self) throws -> COMReference<Other> /* where Interface: COMIUnknownStruct */ {
        try interop.queryInterface(id, type: type)
    }

    // Should require COMIUnknownStruct but we run into compiler bugs.
    public consuming func cast<Other>(to type: Other.Type = Other.self) -> COMReference<Other> /* where Interface: COMIUnknownStruct */ {
        let pointer = self.pointer
        discard self
        return COMReference<Other>(transferringRef: pointer.withMemoryRebound(to: Other.self, capacity: 1) { $0 })
    }

    deinit {
        interop.release()
    }
}
