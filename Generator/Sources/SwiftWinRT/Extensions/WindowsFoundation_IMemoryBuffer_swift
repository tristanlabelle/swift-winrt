import WindowsRuntime

extension Array where Element == UInt8 {
    public init(_ buffer: WindowsFoundation_IMemoryBuffer) throws {
        let reference = try buffer.createReference()
        guard let bufferPointer = try reference.bytes else { throw COMError.fail }
        self.init(bufferPointer)
    }
}