import COM_ABI

/// Holds a strong reference to a COM object, releasing it when deinitialized, like a C++ smart pointer.
public struct COMReference<ABIStruct>: ~Copyable {
    public var pointer: UnsafeMutablePointer<ABIStruct>

    public init(transferringRef pointer: UnsafeMutablePointer<ABIStruct>) {
        self.pointer = pointer
    }

    public init(addingRef pointer: UnsafeMutablePointer<ABIStruct>) {
        self.init(transferringRef: pointer)
        interop.addRef()
    }

    public var interop: COMInterop<ABIStruct> { .init(pointer) }

    public func clone() -> COMReference<ABIStruct> { .init(addingRef: pointer) }

    public consuming func detach() -> UnsafeMutablePointer<ABIStruct> {
        let pointer = self.pointer
        discard self
        return pointer
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        try interop.queryInterface(id)
    }

    public func queryInterface<OtherABIStruct>(
            _ id: COMInterfaceID, type: OtherABIStruct.Type = OtherABIStruct.self) throws -> COMReference<OtherABIStruct> {
        try interop.queryInterface(id, type: type)
    }

    public consuming func cast<OtherABIStruct>(
            to type: OtherABIStruct.Type = OtherABIStruct.self) -> COMReference<OtherABIStruct> {
        let pointer = self.pointer
        discard self
        return COMReference<OtherABIStruct>(transferringRef: pointer.withMemoryRebound(to: OtherABIStruct.self, capacity: 1) { $0 })
    }

    deinit {
        interop.release()
    }
}
