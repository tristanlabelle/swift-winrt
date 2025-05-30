import XCTest
import WinRTComponent

class ArrayTests: WinRTTestCase {
    func testInput() throws {
        XCTAssertEqual(try WinRTComponent_Arrays.getLast(["a", "b"]), "b")
    }

    func testReturn() throws {
        XCTAssertEqual(try WinRTComponent_Arrays.make("a", "b"), ["a", "b"])
    }

    func testOutParam() throws {
        var array = [String]()
        try WinRTComponent_Arrays.output("a", "b", &array)
        XCTAssertEqual(array, ["a", "b"])
    }

    func testByRef() throws {
        throw XCTSkip("Not implemented: byref arrays")
    }
}