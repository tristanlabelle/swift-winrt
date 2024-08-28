import XCTest
import WindowsRuntime

internal final class IInspectableBoxingTests: WinRTTestCase {
    func testMismatchedUnboxing() throws {
        let inspectable = try IInspectableBoxing.box(true)
        XCTAssertThrowsError(try IInspectableBoxing.unboxInt32(inspectable))
    }

    func testInertPrimitive() throws {
        let inspectable = try IInspectableBoxing.box(true)
        XCTAssertEqual(try IInspectableBoxing.unboxBoolean(inspectable), true)
    }

    func testAllocatingPrimitive() throws {
        let inspectable = try IInspectableBoxing.box("test")
        XCTAssertEqual(try IInspectableBoxing.unboxString(inspectable), "test")
    }

    func testStruct() throws {
        let inspectable = try IInspectableBoxing.box(WindowsFoundation_Point(x: 1, y: 2))
        XCTAssertEqual(
            try IInspectableBoxing.unbox(inspectable, projection: WindowsFoundation_Point.self),
            WindowsFoundation_Point(x: 1, y: 2))
    }

    func testEnum() throws {
        let inspectable = try IInspectableBoxing.box(WindowsFoundation_PropertyType.boolean)
        XCTAssertEqual(
            try IInspectableBoxing.unbox(inspectable, projection: WindowsFoundation_PropertyType.self),
            WindowsFoundation_PropertyType.boolean)
    }

    func testInertPrimitiveArray() throws {
        let inspectable = try IInspectableBoxing.box([true])
        XCTAssertEqual(try IInspectableBoxing.unboxBooleanArray(inspectable), [true])
    }

    func testAllocatingPrimitiveArray() throws {
        let inspectable = try IInspectableBoxing.box(["test"])
        XCTAssertEqual(try IInspectableBoxing.unboxStringArray(inspectable), ["test"])
    }

    func testEnumArray() throws {
        let inspectable = try IInspectableBoxing.box([WindowsFoundation_PropertyType.boolean])
        XCTAssertEqual(
            try IInspectableBoxing.unboxArray(inspectable, projection: WindowsFoundation_PropertyType.self),
            [WindowsFoundation_PropertyType.boolean])
    }

    func testStructArray() throws {
        let inspectable = try IInspectableBoxing.box([WindowsFoundation_Point(x: 1, y: 2)])
        XCTAssertEqual(
            try IInspectableBoxing.unboxArray(inspectable, projection: WindowsFoundation_Point.self),
            [WindowsFoundation_Point(x: 1, y: 2)])
    }
}