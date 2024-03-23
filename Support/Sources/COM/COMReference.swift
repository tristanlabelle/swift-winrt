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

    // Should require COMIUnknownStruct but we run into compiler bugs.
    public consuming func reinterpret<NewInterface>(to type: NewInterface.Type = NewInterface.self) -> COMReference<NewInterface> /* where Interface: COMIUnknownStruct */ {
        let pointer = self.pointer
        discard self
        return COMReference<NewInterface>(transferringRef: pointer.withMemoryRebound(to: NewInterface.self, capacity: 1) { $0 })
    }

    deinit {
        interop.release()
    }
}

public typealias IUnknownReference = COMReference<WindowsRuntime_ABI.SWRT_IUnknown>