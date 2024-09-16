import WindowsRuntime

extension WindowsStorageStreams_Buffer {
    public convenience init(_ bytes: [UInt8]) throws {
        try self.init(UInt32(bytes.count))
        try self._length(UInt32(bytes.count))
        let byteAccess = try self._queryInterface(IBufferByteAccessBinding.self)
        let bufferPointer = try UnsafeMutableBufferPointer(start: byteAccess.interop.buffer(), count: bytes.count)
        _ = bufferPointer.update(fromContentsOf: bytes)
    }
}
