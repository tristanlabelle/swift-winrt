import XCTest
import WinRTComponent

class BufferTests: WinRTTestCase {
    private static let bytes: [UInt8] = [1, 2]

    func testConsumingIBuffer() throws {
        let buffer = try ByteBuffers.CreateBuffer(bytes)
        let byteAccess = try buffer.queryInterface(IBufferByteAccessProjection.self)
        let roundtripped = [UInt8](UnsafeMutableBufferPointer(start: try byteAccess.buffer, count: try buffer._length()))
        XCTAssertEqual(roundtripped, bytes)
    }

    func testProducingIBuffer() throws {
        class MyBuffer: WinRTExport<IBufferProjection>, IBufferProtocol, IBufferByteAccessProtocol {
            override class var implements: [COMImplements] { [
                .init(IBufferByteAccessProjection.self)
            ] }

            private var bytes: [UInt8]
            init(bytes: [UInt8]) { self.bytes = bytes }

            func _length() throws -> UInt32 { UInt32(bytes.count) }
            func _data() throws -> UnsafeMutablePointer<UInt8> {
                return UnsafeMutablePointer(mutating: bytes)
            }
        }
    }

    func testConsumingIMemoryBuffer() throws {
        // let buffer = try ByteBuffers.CreateMemoryBuffer(bytes)
        // let bufferReference = try buffer.createReference()
        // let byteAccess = try bufferReference.queryInterface(IMemoryBufferByteAccessProjection.self)
        // let roundtripped = [UInt8](try byteAccess.buffer)
        // XCTAssertEqual(roundtripped, bytes)
    }
}