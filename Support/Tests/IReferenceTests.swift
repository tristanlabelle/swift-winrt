import XCTest
import WindowsRuntime

internal final class IReferenceTests: WinRTTestCase {
    func testPODPrimitive() throws {
        let ireference = try createIReference(true)
        XCTAssertEqual(try ireference.getRuntimeClassName(), "Windows.Foundation.IReference`1<Boolean>")
        XCTAssertEqual(try ireference.type, .boolean)
        XCTAssertEqual(try ireference.value, true)
    }

    func testAllocatingPrimitive() throws {
        let ireference = try createIReference("test")
        XCTAssertEqual(try ireference.getRuntimeClassName(), "Windows.Foundation.IReference`1<String>")
        XCTAssertEqual(try ireference.type, .string)
        XCTAssertEqual(try ireference.value, "test")
    }

    func testEnum() throws {
        let ireference = try createIReference(WindowsFoundation_PropertyType.boolean)
        XCTAssertEqual(try ireference.getRuntimeClassName(), "Windows.Foundation.IReference`1<Windows.Foundation.PropertyType>")
        XCTAssertEqual(try ireference.type, .otherType)
        XCTAssertEqual(try ireference.value, WindowsFoundation_PropertyType.boolean)
    }

    func testStruct() throws {
        let ireference = try createIReference(WindowsFoundation_Point(x: 1, y: 2))
        XCTAssertEqual(try ireference.getRuntimeClassName(), "Windows.Foundation.IReference`1<Windows.Foundation.Point>")
        XCTAssertEqual(try ireference.type, .point)
        XCTAssertEqual(try ireference.value, WindowsFoundation_Point(x: 1, y: 2))
    }

    func testPODPrimitiveArray() throws {
        let ireferenceArray = try createIReferenceArray([true])
        XCTAssertEqual(try ireferenceArray.getRuntimeClassName(), "Windows.Foundation.IReferenceArray`1<Boolean>")
        XCTAssertEqual(try ireferenceArray.type, .booleanArray)
        XCTAssertEqual(try ireferenceArray.value, [true])
    }

    func testAllocatingPrimitiveArray() throws {
        let ireferenceArray = try createIReferenceArray(["test"])
        XCTAssertEqual(try ireferenceArray.getRuntimeClassName(), "Windows.Foundation.IReferenceArray`1<String>")
        XCTAssertEqual(try ireferenceArray.type, .stringArray)
        XCTAssertEqual(try ireferenceArray.value, ["test"])
    }

    func testEnumArray() throws {
        let ireferenceArray = try createIReferenceArray([WindowsFoundation_PropertyType.boolean])
        XCTAssertEqual(try ireferenceArray.getRuntimeClassName(), "Windows.Foundation.IReferenceArray`1<Windows.Foundation.PropertyType>")
        XCTAssertEqual(try ireferenceArray.type, .otherTypeArray)
        XCTAssertEqual(try ireferenceArray.value, [WindowsFoundation_PropertyType.boolean])
    }

    func testStructArray() throws {
        let ireferenceArray = try createIReferenceArray([WindowsFoundation_Point(x: 1, y: 2)])
        XCTAssertEqual(try ireferenceArray.getRuntimeClassName(), "Windows.Foundation.IReferenceArray`1<Windows.Foundation.Point>")
        XCTAssertEqual(try ireferenceArray.type, .pointArray)
        XCTAssertEqual(try ireferenceArray.value, [WindowsFoundation_Point(x: 1, y: 2)])
    }
}
