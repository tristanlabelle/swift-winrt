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

    func testFlagsSetAlgebra() throws {
        XCTAssertEqual(FlagsEnum.all.intersection(FlagsEnum.bit16), try Enums.bitwiseAnd(FlagsEnum.all, FlagsEnum.bit16))
        XCTAssertEqual(FlagsEnum.bit16.intersection(FlagsEnum.all), try Enums.bitwiseAnd(FlagsEnum.bit16, FlagsEnum.all))
        XCTAssertEqual(FlagsEnum.bit0.union(FlagsEnum.bit16), try Enums.bitwiseOr(FlagsEnum.bit0, FlagsEnum.bit16))
        XCTAssertEqual(FlagsEnum.bit16.union(FlagsEnum.bit0), try Enums.bitwiseOr(FlagsEnum.bit16, FlagsEnum.bit0))
    }
}