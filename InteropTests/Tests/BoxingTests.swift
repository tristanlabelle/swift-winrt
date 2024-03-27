import WindowsRuntime
import WinRTComponent
import XCTest

class BoxingTests: WinRTTestCase {
    typealias CppBoxing = WinRTComponent.Boxing
    typealias SwiftBoxing = WindowsRuntime.IInspectableBoxing

    func testRoundTripOfPrimitiveTypeWithIdentityProjection() throws {
        let original = Int32(42)
        XCTAssertEqual(try SwiftBoxing.unboxInt32(SwiftBoxing.box(original)), original)
        XCTAssertEqual(try SwiftBoxing.unboxInt32(CppBoxing.boxInt32(original)), original)
        XCTAssertEqual(try CppBoxing.unboxInt32(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfPrimitiveTypeWithAllocatingProjection() throws {
        let original = "Hello"
        XCTAssertEqual(try SwiftBoxing.unboxString(SwiftBoxing.box(original)), original)
        XCTAssertEqual(try SwiftBoxing.unboxString(CppBoxing.boxString(original)), original)
        XCTAssertEqual(try CppBoxing.unboxString(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfEnumType() throws {
        let original = MinimalEnum.one
        XCTAssertEqual(try SwiftBoxing.unbox(SwiftBoxing.box(original), projection: MinimalEnum.self), original)
        XCTAssertEqual(try SwiftBoxing.unbox(CppBoxing.boxMinimalEnum(original), projection: MinimalEnum.self), original)
        XCTAssertEqual(try CppBoxing.unboxMinimalEnum(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfStructType() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try SwiftBoxing.unbox(SwiftBoxing.box(original), projection: MinimalStruct.self), original)
        XCTAssertEqual(try SwiftBoxing.unbox(CppBoxing.boxMinimalStruct(original), projection: MinimalStruct.self), original)
        XCTAssertEqual(try CppBoxing.unboxMinimalStruct(SwiftBoxing.box(original)), original)
    }
}
