import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class PropertyTests: WinRTTestCase {
    func testInstance() throws {
        let wrapper = try Int32Wrapper()

        func assertGet(expected: Int32) throws {
            XCTAssertEqual(try wrapper.getOnly, expected)
            XCTAssertEqual(try wrapper.getSet, expected)
            XCTAssertEqual(wrapper.getSet_, expected)
        }

        try assertGet(expected: 0)

        try wrapper.getSet(1)
        try assertGet(expected: 1)

        wrapper.getSet_ = 2
        try assertGet(expected: 2)
    }

    func testStatic() throws {
        func assertGet(expected: Int32) throws {
            XCTAssertEqual(try Int32Global.getOnly, expected)
            XCTAssertEqual(try Int32Global.getSet, expected)
            XCTAssertEqual(Int32Global.getSet_, expected)
        }

        try Int32Global.getSet(0)
        try assertGet(expected: 0)

        try Int32Global.getSet(1)
        try assertGet(expected: 1)

        Int32Global.getSet_ = 2
        try assertGet(expected: 2)
    }
}