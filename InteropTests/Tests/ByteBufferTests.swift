import UWP_WindowsFoundation
import UWP_WindowsStorageStreams
import WindowsRuntime
import WinRTComponent
import XCTest

class ByteBufferTests : XCTestCase {
    public func testConsumeMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let memoryBuffer = try ByteBuffers.arrayToMemoryBuffer(bytes)
        let memoryBufferReference = try memoryBuffer.createReference()
        let roundtrippedBytes = try Array(memoryBufferReference.bytes)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testConsumeStorageBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        var storageBuffer = try ByteBuffers.arrayToStorageBuffer(bytes)
        let roundtrippedBytes = Array(UnsafeMutableBufferPointer(start: storageBuffer.bytes, count: Int(storageBuffer._length()))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceMemoryBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        let memoryBuffer = try MemoryBuffer(UInt32(bytes.count))
        try memoryBuffer.createReference().bytes.update(fromContentsOf: bytes)
        var roundtrippedBytes = try ByteBuffers.memoryBufferToArray(memoryBuffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceStorageBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        let buffer = try Buffer(UInt32(bytes.count))
        try UnsafeMutableBufferPointer(start: buffer.bytes, count: Int(buffer._length()))
            .update(fromContentsOf: bytes)
        var roundtrippedBytes = try ByteBuffers.storageBufferToArray(buffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }
}