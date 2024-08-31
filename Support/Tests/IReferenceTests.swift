import XCTest
import WindowsRuntime

internal final class IReferenceTests: WinRTTestCase {
    func testInertPrimitive() throws {
        let ireference = try createIReference(true)
        XCTAssertEqual(try ireference._value(), true)
    }

    func testAllocatingPrimitive() throws {
        let ireference = try createIReference("test")
        XCTAssertEqual(try ireference._value(), "test")
    }

    func testEnum() throws {
        let ireference = try createIReference(WindowsFoundation_PropertyType.boolean)
        XCTAssertEqual(try ireference._value(), WindowsFoundation_PropertyType.boolean)
    }

    func testStruct() throws {
        let ireference = try createIReference(WindowsFoundation_Point(x: 1, y: 2))
        XCTAssertEqual(try ireference._value(), WindowsFoundation_Point(x: 1, y: 2))
    }

    func testInertPrimitiveArray() throws {
        let ireferenceArray = try createIReferenceArray([true])
        XCTAssertEqual(try ireferenceArray._value(), [true])
    }

    func testAllocatingPrimitiveArray() throws {
        let ireferenceArray = try createIReferenceArray(["test"])
        XCTAssertEqual(try ireferenceArray._value(), ["test"])
    }

    func testEnumArray() throws {
        let ireferenceArray = try createIReferenceArray([WindowsFoundation_PropertyType.boolean])
        XCTAssertEqual(try ireferenceArray._value(), [WindowsFoundation_PropertyType.boolean])
    }

    func testStructArray() throws {
        let ireferenceArray = try createIReferenceArray([WindowsFoundation_Point(x: 1, y: 2)])
        XCTAssertEqual(try ireferenceArray._value(), [WindowsFoundation_Point(x: 1, y: 2)])
    }
}