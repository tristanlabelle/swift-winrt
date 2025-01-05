import XCTest
import WinRTComponent

// Compile-time test that the type was generated as a Swift enum
import enum WinRTComponent.SwiftEnum

class EnumTests: WinRTTestCase {
    func testNonFlags() throws {
        XCTAssert(WinRTComponent_SignedEnum.RawValue.self == Int32.self)
        XCTAssertEqual(WinRTComponent_SignedEnum.min.rawValue, Int32.min)
        XCTAssertEqual(WinRTComponent_SignedEnum.negativeOne.rawValue, -1)
        XCTAssertEqual(WinRTComponent_SignedEnum.zero.rawValue, 0)
        XCTAssertEqual(WinRTComponent_SignedEnum.one.rawValue, 1)
        XCTAssertEqual(WinRTComponent_SignedEnum.max.rawValue, Int32.max)
    }

    func testFlags() throws {
        XCTAssert(WinRTComponent_FlagsEnum.RawValue.self == UInt32.self)
        XCTAssertEqual(WinRTComponent_FlagsEnum.none.rawValue, 0)
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit0.rawValue, 1)
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit16.rawValue, 0x10000)
        XCTAssertEqual(WinRTComponent_FlagsEnum.all.rawValue, 0xFFFFFFFF)
    }

    func testFlagsBitwiseOperators() throws {
        XCTAssertEqual(~WinRTComponent_FlagsEnum.all, WinRTComponent_FlagsEnum.none)
        XCTAssertEqual(WinRTComponent_FlagsEnum.all & WinRTComponent_FlagsEnum.bit16, WinRTComponent_FlagsEnum.bit16)
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit16 & WinRTComponent_FlagsEnum.all, WinRTComponent_FlagsEnum.bit16)
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit0 | WinRTComponent_FlagsEnum.bit16, WinRTComponent_FlagsEnum(rawValue: 0x10001))
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit16 | WinRTComponent_FlagsEnum.bit0, WinRTComponent_FlagsEnum(rawValue: 0x10001))
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit0 ^ WinRTComponent_FlagsEnum.bit0, WinRTComponent_FlagsEnum.none)
        XCTAssertEqual(WinRTComponent_FlagsEnum.bit0 ^ WinRTComponent_FlagsEnum.bit16, WinRTComponent_FlagsEnum(rawValue: 0x10001))
    }
}