import XCTest
import WinRTComponent

class ArrayTests: WinRTTestCase {
    func testInputOfInt32() throws {
        XCTAssertEqual(try Arrays.getLastInt32([1, 2]), 2)
    }

    func testReturnOfInt32() throws {
        XCTAssertEqual(try Arrays.makeInt32(1, 2), [1, 2])
    }

    func testOutParamOfInt32() throws {
        var array = [Int32]()
        try Arrays.outputInt32(1, 2, &array)
        XCTAssertEqual(array, [1, 2])
    }

    // func testByRefOfInt32() throws {
    //     var array: [Int32] = [1, 2]
    //     try Arrays.swapFirstLastInt32(array)
    // }

    func testInputOfString() throws {
        XCTAssertEqual(try Arrays.getLastString(["a", "b"]), "b")
    }

    func testReturnOfString() throws {
        XCTAssertEqual(try Arrays.makeString("a", "b"), ["a", "b"])
    }

    func testOutParamOfString() throws {
        var array = [String]()
        try Arrays.outputString("a", "b", &array)
        XCTAssertEqual(array, ["a", "b"])
    }
}