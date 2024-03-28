import WindowsRuntime
import WinRTComponent
import XCTest

class InspectableBoxingTests: WinRTTestCase {
    typealias CppBoxing = WinRTComponent.InspectableBoxing
    typealias SwiftBoxing = WindowsRuntime.IInspectableBoxing

    func testRoundTripOfPrimitiveWithIdentityProjection() throws {
        let original = Int32(42)
        XCTAssertEqual(try SwiftBoxing.unboxInt32(SwiftBoxing.box(original)), original)
        XCTAssertEqual(try SwiftBoxing.unboxInt32(CppBoxing.boxInt32(original)), original)
        XCTAssertEqual(try CppBoxing.unboxInt32(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfPrimitiveWithAllocatingProjection() throws {
        let original = "Hello"
        XCTAssertEqual(try SwiftBoxing.unboxString(SwiftBoxing.box(original)), original)
        XCTAssertEqual(try SwiftBoxing.unboxString(CppBoxing.boxString(original)), original)
        XCTAssertEqual(try CppBoxing.unboxString(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfEnum() throws {
        let original = MinimalEnum.one
        XCTAssertEqual(try SwiftBoxing.unbox(SwiftBoxing.box(original), projection: MinimalEnum.self), original)
        XCTAssertEqual(try SwiftBoxing.unbox(CppBoxing.boxMinimalEnum(original), projection: MinimalEnum.self), original)
        XCTAssertEqual(try CppBoxing.unboxMinimalEnum(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfStruct() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try SwiftBoxing.unbox(SwiftBoxing.box(original), projection: MinimalStruct.self), original)
        XCTAssertEqual(try SwiftBoxing.unbox(CppBoxing.boxMinimalStruct(original), projection: MinimalStruct.self), original)
        XCTAssertEqual(try CppBoxing.unboxMinimalStruct(SwiftBoxing.box(original)), original)
    }

    func testRoundTripOfDelegate() throws {
        func assertRoundTrip(roundtrip: (@escaping MinimalDelegate) throws -> MinimalDelegate) throws {
            var invoked = false
            let original: MinimalDelegate = { invoked = true }
            let roundtripped = try roundtrip(original)
            XCTAssertFalse(invoked)
            try roundtripped()
            XCTAssertTrue(invoked)
        }

        try assertRoundTrip {
            let boxed = try SwiftBoxing.box($0, projection: MinimalDelegateProjection.self)
            return try XCTUnwrap(SwiftBoxing.unbox(boxed, projection: MinimalDelegateProjection.self))
        }

        try assertRoundTrip {
            let boxed = try CppBoxing.boxMinimalDelegate($0)
            return try XCTUnwrap(SwiftBoxing.unbox(boxed, projection: MinimalDelegateProjection.self))
        }

        try assertRoundTrip {
            let boxed = try SwiftBoxing.box($0, projection: MinimalDelegateProjection.self)
            return try CppBoxing.unboxMinimalDelegate(boxed)
        }
    }
}
