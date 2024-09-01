import WindowsRuntime

extension WindowsFoundation_MemoryBuffer {
    public convenience init(_ bytes: [UInt8]) throws {
        try self.init(UInt32(bytes.count))
        let reference = try self.createReference()
        guard let bufferPointer = try reference.bytes else { throw COMError.fail }
        _ = bufferPointer.update(fromContentsOf: bytes)
    }
}