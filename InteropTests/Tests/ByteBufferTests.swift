import UWP
import WindowsRuntime
import WinRTComponent
import XCTest

class ByteBufferTests : XCTestCase {
    public func testConsumeMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try Array(WinRTComponent_ByteBuffers.arrayToMemoryBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testConsumeStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try Array(WinRTComponent_ByteBuffers.arrayToStorageBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceMemoryBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try WinRTComponent_ByteBuffers.memoryBufferToArray(try WindowsFoundation_MemoryBuffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }

    public func testProduceStorageBuffer() throws {
        let bytes: [UInt8] = [1, 2, 3]
        let roundtrippedBytes = try WinRTComponent_ByteBuffers.storageBufferToArray(try WindowsStorageStreams_Buffer(bytes))
        XCTAssertEqual(roundtrippedBytes, bytes)
    }
}