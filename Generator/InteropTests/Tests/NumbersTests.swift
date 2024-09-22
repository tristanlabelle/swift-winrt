import XCTest
import WinRTComponent

class NumberTests: WinRTTestCase {
    func testBool() throws {
        XCTAssertEqual(try Numbers.not(false), true)
    }

    func testIntegers() throws {
        XCTAssertEqual(try Numbers.incrementUInt8(1), 2)
        XCTAssertEqual(try Numbers.incrementInt16(0xFF), 0x100)
        XCTAssertEqual(try Numbers.incrementUInt16(0xFF), 0x100)
        XCTAssertEqual(try Numbers.incrementInt32(0xFFFF), 0x1_0000)
        XCTAssertEqual(try Numbers.incrementUInt32(0xFFFF), 0x1_0000)
        XCTAssertEqual(try Numbers.incrementInt64(0xFFFF_FFFF), 0x1_0000_0000)
        XCTAssertEqual(try Numbers.incrementUInt64(0xFFFF_FFFF), 0x1_0000_0000)
    }

    func testSignedIntegerOverflow() throws {
        XCTAssertEqual(try Numbers.incrementInt16(Int16.max), Int16.min)
        XCTAssertEqual(try Numbers.incrementInt32(Int32.max), Int32.min)
        XCTAssertEqual(try Numbers.incrementInt64(Int64.max), Int64.min)
    }

    func testUnsignedSignedIntegerOverflow() throws {
        XCTAssertEqual(try Numbers.incrementUInt8(UInt8.max), 0)
        XCTAssertEqual(try Numbers.incrementUInt16(UInt16.max), 0)
        XCTAssertEqual(try Numbers.incrementUInt32(UInt32.max), 0)
        XCTAssertEqual(try Numbers.incrementUInt64(UInt64.max), 0)
    }

    func testSingle() throws {
        XCTAssertEqual(try Numbers.negateSingle(42), -42)
        XCTAssertEqual(try Numbers.negateDouble(42), -42)
    }
}