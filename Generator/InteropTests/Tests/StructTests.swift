import XCTest
import WinRTComponent

class StructTests: WinRTTestCase {
    func testAsReturnValue() throws {
        let result = try Structs.make(1, "a", 11, LeafStruct(int32: 2, string: "b", reference: 22))
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.reference, 11)
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
        XCTAssertEqual(result.nested.reference, 22)
    }

    func testAsArgument() throws {
        let value = Struct(int32: 1, string: "a", reference: 11, nested: LeafStruct(int32: 2, string: "b", reference: 22))
        XCTAssertEqual(try Structs.getInt32(value), 1)
        XCTAssertEqual(try Structs.getString(value), "a")
        XCTAssertEqual(try Structs.getReference(value), 11)
        let nested = try Structs.getNested(value)
        XCTAssertEqual(nested.int32, 2)
        XCTAssertEqual(nested.string, "b")
        XCTAssertEqual(nested.reference, 22)
    }

    func testAsOutParam() throws {
        var result: Struct = .init()
        try Structs.output(1, "a", 11, LeafStruct(int32: 2, string: "b", reference: 22), &result)
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.reference, 11)
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
        XCTAssertEqual(result.nested.reference, 22)
    }

    func testAsConstByRefArgument() throws {
        // Currently "ref const" maps to in params
        let value = Struct(int32: 1, string: "a", reference: 11, nested: LeafStruct(int32: 2, string: "b", reference: 22))
        let roundtripped = try Structs.returnRefConstArgument(value)
        XCTAssertEqual(roundtripped.int32, 1)
        XCTAssertEqual(roundtripped.string, "a")
        XCTAssertEqual(roundtripped.reference, 11)
        XCTAssertEqual(roundtripped.nested.int32, 2)
        XCTAssertEqual(roundtripped.nested.string, "b")
        XCTAssertEqual(roundtripped.nested.reference, 22)
    }
}