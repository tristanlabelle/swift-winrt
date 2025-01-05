import WindowsRuntime
import WinRTComponent
import XCTest

class ReferenceBoxingTests: WinRTTestCase {
    func testRoundTripOfPrimitiveWithIdentityBinding() throws {
        let original = Int32(42)
        XCTAssertEqual(try XCTUnwrap(WinRTComponent_ReferenceBoxing.boxInt32(original)), original)
        XCTAssertEqual(try WinRTComponent_ReferenceBoxing.unboxInt32(Optional(original)), original)
        XCTAssertThrowsError(try WinRTComponent_ReferenceBoxing.unboxInt32(nil))
    }

    func testRoundTripOfEnum() throws {
        let original = WinRTComponent_MinimalEnum.one
        XCTAssertEqual(try XCTUnwrap(WinRTComponent_ReferenceBoxing.boxMinimalEnum(original)), original)
        XCTAssertEqual(try WinRTComponent_ReferenceBoxing.unboxMinimalEnum(Optional(original)), original)
        XCTAssertThrowsError(try WinRTComponent_ReferenceBoxing.unboxMinimalEnum(nil))
    }

    func testRoundTripOfStruct() throws {
        let original = WinRTComponent_MinimalStruct(field: 42)
        XCTAssertEqual(try XCTUnwrap(WinRTComponent_ReferenceBoxing.boxMinimalStruct(original)), original)
        XCTAssertEqual(try WinRTComponent_ReferenceBoxing.unboxMinimalStruct(Optional(original)), original)
        XCTAssertThrowsError(try WinRTComponent_ReferenceBoxing.unboxMinimalStruct(nil))
    }
}
