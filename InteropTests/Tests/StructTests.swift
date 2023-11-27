import XCTest
import WinRTComponent

class StructTests: WinRTTestCase {
    func testAsReturnValue() throws {
        let result = try Structs.make(1, "a", LeafStruct(int32: 2, string: "b"))
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
    }

    func testAsArgument() throws {
        let result = Struct(int32: 1, string: "a", nested: LeafStruct(int32: 2, string: "b"))
        XCTAssertEqual(try Structs.getInt32(result), 1)
        XCTAssertEqual(try Structs.getString(result), "a")
        let nested = try Structs.getNested(result)
        XCTAssertEqual(nested.int32, 2)
        XCTAssertEqual(nested.string, "b")
    }

    func testAsOutParam() throws {
        var result: Struct = .init()
        try Structs.output(1, "a", LeafStruct(int32: 2, string: "b"), &result)
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
    }
}