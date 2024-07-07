/// Lazily initialized reference to a COM object.
/// Essentially an Optional<COMReference<ABIStruct>> without language support.
public struct COMLazyReference<ABIStruct>: ~Copyable {
    private var pointer: UnsafeMutablePointer<ABIStruct>?

    public init() {
        self.pointer = nil
    }

    public init(_ reference: consuming COMReference<ABIStruct>) {
        self.pointer = reference.detach()
    }

    public mutating func getPointer(_ factory: () throws -> COMReference<ABIStruct>) rethrows -> UnsafeMutablePointer<ABIStruct> {
        if let pointer { return pointer }
        let new = try factory().detach()
        self.pointer = new
        return new
    }

    public mutating func getInterop(_ factory: () throws -> COMReference<ABIStruct>) rethrows -> COMInterop<ABIStruct> {
        try COMInterop(getPointer(factory))
    }

    deinit {
        if let pointer {
            COMInterop(pointer).release()
        }
    }
}