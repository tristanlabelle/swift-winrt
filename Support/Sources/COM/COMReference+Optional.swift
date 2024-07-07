extension COMReference {
    /// Smart pointer-like reference to a COM object or to nil.
    /// Essentially an Optional<ABIReference> without language support.
    public struct Optional: ~Copyable {
        public static var none: Self { Self() }

        private var pointer: UnsafeMutablePointer<ABIStruct>?

        public init() {
            self.pointer = nil
        }

        public init(_ reference: consuming COMReference<ABIStruct>) {
            self.pointer = reference.detach()
        }

        public mutating func detach() -> UnsafeMutablePointer<ABIStruct>? {
            defer { pointer = nil }
            return pointer
        }

        public consuming func finalDetach() -> UnsafeMutablePointer<ABIStruct>? {
            let pointer = self.pointer
            discard self
            return pointer
        }

        public mutating func lazyInitPointer(_ factory: () throws -> COMReference<ABIStruct>) rethrows -> UnsafeMutablePointer<ABIStruct> {
            if let pointer { return pointer }
            let new = try factory().detach()
            self.pointer = new
            return new
        }

        public mutating func lazyInitInterop(_ factory: () throws -> COMReference<ABIStruct>) rethrows -> COMInterop<ABIStruct> {
            try COMInterop(lazyInitPointer(factory))
        }

        deinit {
            if let pointer {
                COMInterop(pointer).release()
            }
        }
    }
}