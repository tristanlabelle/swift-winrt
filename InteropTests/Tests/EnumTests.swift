import XCTest
import WinRTComponent

// Compile-time test that the type was generated as a Swift enum
import enum WinRTComponent.SwiftEnum

class EnumTests: WinRTTestCase {
    func testNonFlags() throws {
        XCTAssert(SignedEnum.RawValue.self == Int32.self)
        XCTAssertEqual(SignedEnum.min.rawValue, Int32.min)
        XCTAssertEqual(SignedEnum.negativeOne.rawValue, -1)
        XCTAssertEqual(SignedEnum.zero.rawValue, 0)
        XCTAssertEqual(SignedEnum.one.rawValue, 1)
        XCTAssertEqual(SignedEnum.max.rawValue, Int32.max)
    }

    func testFlags() throws {
        XCTAssert(FlagsEnum.RawValue.self == UInt32.self)
        XCTAssertEqual(FlagsEnum.none.rawValue, 0)
        XCTAssertEqual(FlagsEnum.bit0.rawValue, 1)
        XCTAssertEqual(FlagsEnum.bit16.rawValue, 0x10000)
        XCTAssertEqual(FlagsEnum.all.rawValue, 0xFFFFFFFF)
    }

    func testFlagsBitwiseOperators() throws {
        XCTAssertEqual(~FlagsEnum.all, FlagsEnum.none)
        XCTAssertEqual(FlagsEnum.all & FlagsEnum.bit16, FlagsEnum.bit16)
        XCTAssertEqual(FlagsEnum.bit16 & FlagsEnum.all, FlagsEnum.bit16)
        XCTAssertEqual(FlagsEnum.bit0 | FlagsEnum.bit16, FlagsEnum(rawValue: 0x10001))
        XCTAssertEqual(FlagsEnum.bit16 | FlagsEnum.bit0, FlagsEnum(rawValue: 0x10001))
        XCTAssertEqual(FlagsEnum.bit0 ^ FlagsEnum.bit0, FlagsEnum.none)
        XCTAssertEqual(FlagsEnum.bit0 ^ FlagsEnum.bit16, FlagsEnum(rawValue: 0x10001))
    }
}