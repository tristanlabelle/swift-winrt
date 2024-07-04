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
        let roundtrippedBytes = try Array(UnsafeBufferPointer(start: memoryBufferReference.bytes, count: Int(memoryBufferReference._capacity())))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testConsumeStorageBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        var storageBuffer = try ByteBuffers.arrayToStorageBuffer(bytes)
        let roundtrippedBytes = Array(storageBuffer.bytes)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceMemoryBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        let memoryBuffer = try MemoryBuffer(UInt32(bytes.count))
        let memoryBufferReference = try memoryBuffer.createReference()
        let unsafeBuffer = try UnsafeMutableBufferPointer(start: memoryBufferReference.bytes, count: Int(memoryBufferReference._capacity()))
        unsafeBuffer.update(fromContentsOf: bytes)
        var roundtrippedBytes = try ByteBuffers.memoryBufferToArray(memoryBuffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceStorageBuffer() throws {
        var bytes: [UInt8] = [1, 2, 3]
        let buffer = try Buffer(UInt32(bytes.count))
        try buffer.bytes.update(fromContentsOf: bytes)
        var roundtrippedBytes = try ByteBuffers.storageBufferToArray(buffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }
}