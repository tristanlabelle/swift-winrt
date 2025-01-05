import XCTest
import WinRTComponent

class StructTests: WinRTTestCase {
    func testAsReturnValue() throws {
        let result = try WinRTComponent_Structs.make(1, "a", 11,
            WinRTComponent_LeafStruct(int32: 2, string: "b", reference: 22))
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.reference, 11)
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
        XCTAssertEqual(result.nested.reference, 22)
    }

    func testAsArgument() throws {
        let value = WinRTComponent_Struct(int32: 1, string: "a", reference: 11,
            nested: WinRTComponent_LeafStruct(int32: 2, string: "b", reference: 22))
        XCTAssertEqual(try WinRTComponent_Structs.getInt32(value), 1)
        XCTAssertEqual(try WinRTComponent_Structs.getString(value), "a")
        XCTAssertEqual(try WinRTComponent_Structs.getReference(value), 11)
        let nested = try WinRTComponent_Structs.getNested(value)
        XCTAssertEqual(nested.int32, 2)
        XCTAssertEqual(nested.string, "b")
        XCTAssertEqual(nested.reference, 22)
    }

    func testAsOutParam() throws {
        var result: WinRTComponent_Struct = .init()
        try WinRTComponent_Structs.output(1, "a", 11,
            WinRTComponent_LeafStruct(int32: 2, string: "b", reference: 22), &result)
        XCTAssertEqual(result.int32, 1)
        XCTAssertEqual(result.string, "a")
        XCTAssertEqual(result.reference, 11)
        XCTAssertEqual(result.nested.int32, 2)
        XCTAssertEqual(result.nested.string, "b")
        XCTAssertEqual(result.nested.reference, 22)
    }

    func testAsConstByRefArgument() throws {
        // Currently "ref const" maps to in params
        let value = WinRTComponent_Struct(int32: 1, string: "a", reference: 11,
            nested: WinRTComponent_LeafStruct(int32: 2, string: "b", reference: 22))
        let roundtripped = try WinRTComponent_Structs.returnRefConstArgument(value)
        XCTAssertEqual(roundtripped.int32, 1)
        XCTAssertEqual(roundtripped.string, "a")
        XCTAssertEqual(roundtripped.reference, 11)
        XCTAssertEqual(roundtripped.nested.int32, 2)
        XCTAssertEqual(roundtripped.nested.string, "b")
        XCTAssertEqual(roundtripped.nested.reference, 22)
    }
}