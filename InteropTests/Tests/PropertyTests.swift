import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class PropertyTests: WinRTTestCase {
    func testInstance() throws {
        let wrapper = try Int32Wrapper()

        func assertGet(expected: Int32) throws {
            XCTAssertEqual(wrapper.getOnly, expected)
            XCTAssertEqual(try wrapper._getOnly(), expected)
            XCTAssertEqual(wrapper.getSet, expected)
            XCTAssertEqual(try wrapper._getSet(), expected)
        }

        try assertGet(expected: 0)

        wrapper.getSet = 1
        try assertGet(expected: 1)

        try wrapper._getSet(2)
        try assertGet(expected: 2)
    }

    func testStatic() throws {
        func assertGet(expected: Int32) throws {
            XCTAssertEqual(Int32Global.getOnly, expected)
            XCTAssertEqual(try Int32Global._getOnly(), expected)
            XCTAssertEqual(Int32Global.getSet, expected)
            XCTAssertEqual(try Int32Global._getSet(), expected)
        }

        Int32Global.getSet = 0
        assertGet(expected: 0)

        Int32Global.getSet = 1
        assertGet(expected: 1)

        try Int32Global._getSet(2)
        assertGet(expected: 2)
    }
}