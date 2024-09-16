import WindowsRuntime

extension WindowsStorageStreams_IBufferProtocol {
    public var bytes: UnsafeMutablePointer<UInt8>? {
        get throws {
            let byteAccess = try self._queryInterface(IBufferByteAccessBinding.self)
            return try byteAccess.interop.buffer()
        }
    }
}

extension Array where Element == UInt8 {
    public init(_ buffer: WindowsStorageStreams_IBuffer) throws {
        self.init(try UnsafeBufferPointer(start: buffer.bytes, count: Int(buffer._length())))
    }
}