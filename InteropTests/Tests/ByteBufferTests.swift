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
        let roundtrippedBytes = try Array(XCTUnwrap(memoryBufferReference.bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testConsumeStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let storageBuffer = try ByteBuffers.arrayToStorageBuffer(bytes)
        let bufferPointer = try UnsafeMutableBufferPointer(start: storageBuffer.bytes, count: Int(storageBuffer._length()))
        let roundtrippedBytes = Array(bufferPointer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let memoryBuffer = try MemoryBuffer(UInt32(bytes.count))
        _ = try XCTUnwrap(XCTUnwrap(memoryBuffer.createReference()).bytes).update(fromContentsOf: bytes)
        let roundtrippedBytes = try ByteBuffers.memoryBufferToArray(memoryBuffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let buffer = try Buffer(UInt32(bytes.count))
        try buffer._length(UInt32(bytes.count))
        let bufferPointer = try UnsafeMutableBufferPointer(start: buffer.bytes, count: Int(buffer._length()))
        let _ = bufferPointer.update(fromContentsOf: bytes)
        let roundtrippedBytes = try ByteBuffers.storageBufferToArray(buffer)
        XCTAssertEqual(roundtrippedBytes, bytes)
    }
}