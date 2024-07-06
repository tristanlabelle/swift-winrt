import UWP_WindowsFoundation
import UWP_WindowsStorageStreams
import WindowsRuntime
import WinRTComponent
import XCTest

class ByteBufferTests : XCTestCase {
    public func testConsumeMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try Array(ByteBuffers.arrayToMemoryBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testConsumeStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try Array(ByteBuffers.arrayToStorageBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try ByteBuffers.memoryBufferToArray(try MemoryBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try ByteBuffers.storageBufferToArray(try Buffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }
}