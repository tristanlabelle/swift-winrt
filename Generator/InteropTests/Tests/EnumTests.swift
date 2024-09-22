import XCTest
import WinRTComponent

class EnumTests: WinRTTestCase {
    func testNonFlags() throws {
        XCTAssert(Enum.RawValue.self == Int32.self)
        XCTAssertEqual(Enum.minusOne.rawValue, -1)
        XCTAssertEqual(Enum.zero.rawValue, 0)
        XCTAssertEqual(Enum.int32Max.rawValue, Int32.max)
    }

    func testFlags() throws {
        XCTAssert(Flags.RawValue.self == UInt32.self)
        XCTAssertEqual(Flags.none.rawValue, 0)
        XCTAssertEqual(Flags.bit0.rawValue, 1)
        XCTAssertEqual(Flags.bit16.rawValue, 0x10000)
        XCTAssertEqual(Flags.all.rawValue, 0xFFFFFFFF)
    }
}