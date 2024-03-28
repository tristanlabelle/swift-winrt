import WindowsRuntime
import WinRTComponent
import XCTest

class ReferenceBoxingTests: WinRTTestCase {
    func testRoundTripOfPrimitiveWithIdentityProjection() throws {
        let original = Int32(42)
        XCTAssertEqual(try XCTUnwrap(ReferenceBoxing.boxInt32(original)), original)
        XCTAssertEqual(try ReferenceBoxing.unboxInt32(Optional(original)), original)
        XCTAssertThrowsError(try ReferenceBoxing.unboxInt32(nil))
    }

    func testRoundTripOfEnum() throws {
        let original = MinimalEnum.one
        XCTAssertEqual(try XCTUnwrap(ReferenceBoxing.boxMinimalEnum(original)), original)
        XCTAssertEqual(try ReferenceBoxing.unboxMinimalEnum(Optional(original)), original)
        XCTAssertThrowsError(try ReferenceBoxing.unboxMinimalEnum(nil))
    }

    func testRoundTripOfStruct() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try XCTUnwrap(ReferenceBoxing.boxMinimalStruct(original)), original)
        XCTAssertEqual(try ReferenceBoxing.unboxMinimalStruct(Optional(original)), original)
        XCTAssertThrowsError(try ReferenceBoxing.unboxMinimalStruct(nil))
    }
}
