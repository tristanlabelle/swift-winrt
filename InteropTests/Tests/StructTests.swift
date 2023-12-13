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
        let value = Struct(int32: 1, string: "a", nested: LeafStruct(int32: 2, string: "b"))
        XCTAssertEqual(try Structs.getInt32(value), 1)
        XCTAssertEqual(try Structs.getString(value), "a")
        let nested = try Structs.getNested(value)
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

    func testAsConstByRefArgument() throws {
        // Currently "ref const" maps to "inout"
        var value = Struct(int32: 1, string: "a", nested: LeafStruct(int32: 2, string: "b"))
        let roundtripped = try Structs.returnRefConstArgument(&value)
        XCTAssertEqual(roundtripped.int32, 1)
        XCTAssertEqual(roundtripped.string, "a")
        XCTAssertEqual(roundtripped.nested.int32, 2)
        XCTAssertEqual(roundtripped.nested.string, "b")
    }
}