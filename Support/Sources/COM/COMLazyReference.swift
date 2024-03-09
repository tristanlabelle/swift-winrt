/// Lazily initialized reference to a COM object.
/// Essentially an Optional<COMReference<Interface>> without language support.
public struct COMLazyReference<Interface: COMIUnknownStruct>: ~Copyable {
    private var pointer: UnsafeMutablePointer<Interface>?

    public init() {
        self.pointer = nil
    }

    public init(_ reference: consuming COMReference<Interface>) {
        self.pointer = reference.detach()
    }

    public mutating func getPointer(_ factory: () throws -> COMReference<Interface>) rethrows -> UnsafeMutablePointer<Interface> {
        if let pointer { return pointer }
        let new = try factory().detach()
        self.pointer = new
        return new
    }

    public mutating func getInterop(_ factory: () throws -> COMReference<Interface>) rethrows -> COMInterop<Interface> {
        try COMInterop(getPointer(factory))
    }

    deinit {
        if let pointer = pointer {
            IUnknownPointer.release(pointer)
        }
    }
}