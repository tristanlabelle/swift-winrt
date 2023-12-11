import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed without loss of information
/// between Swift and WinRT as arguments and return values.
class ValueRoundtripTests: WinRTTestCase {
    private var oneWay: IReturnArgument!
    private var twoWay: IReturnArgument!

    override func setUpWithError() throws {
        try super.setUpWithError()
        oneWay = ReturnArgumentImplementation()
        twoWay = try XCTUnwrap(ReturnArgument.createProxy(oneWay))
    }

    override func tearDownWithError() throws {
        twoWay = nil
        try super.tearDownWithError()
    }

    func testInt32() throws {
        XCTAssertEqual(try twoWay.int32(42), 42)
    }

    func testString() throws {
        XCTAssertEqual(try twoWay.string("foo"), "foo")
    }

    func testObject() throws {
        let original: IInspectable = try MinimalClass()
        let roundtripped = try XCTUnwrap(twoWay.object(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testEnum() throws {
        XCTAssertEqual(try twoWay.enum(.one), .one)
    }

    func testStruct() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try twoWay.struct(original), original)
    }

    func testInterface() throws {
        let original: IMinimalInterface = try MinimalClass()
        let roundtripped = try XCTUnwrap(twoWay.interface(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testClass() throws {
        let instance = try MinimalClass()
        XCTAssertEqual(
            try XCTUnwrap(twoWay.class(instance)).comPointer,
            instance.comPointer)
    }

    func testDelegate() throws {
        // By design, Swift does not support identity comparisons for closures,
        // so we can only test that the round-tripped closure is still calling the same code.
        var called = false
        let result = try XCTUnwrap(twoWay.delegate({ called = true }))
        XCTAssertFalse(called)
        try result()
        XCTAssertTrue(called)
    }

    func testArray_oneWay() throws {
        XCTAssertEqual(try oneWay.array(["a", "b"]), ["a", "b"])
    }

    func testArray_twoWay() throws {
        throw XCTSkip("Two-way array projections are not implemented yet")
    }

    class ReturnArgumentImplementation: WinRTExportBase<IReturnArgumentProjection>, IReturnArgumentProtocol {
        func int32(_ value: Int32) throws -> Int32 { value }
        func string(_ value: String) throws -> String { value }
        func object(_ value: WindowsRuntime.IInspectable?) throws -> WindowsRuntime.IInspectable? { value }
        func `enum`(_ value: WinRTComponent.MinimalEnum) throws -> WinRTComponent.MinimalEnum { value }
        func `struct`(_ value: WinRTComponent.MinimalStruct) throws -> WinRTComponent.MinimalStruct { value }
        func interface(_ value: WinRTComponent.IMinimalInterface?) throws -> WinRTComponent.IMinimalInterface? { value }
        func `class`(_ value: WinRTComponent.MinimalClass?) throws -> WinRTComponent.MinimalClass? { value }
        func delegate(_ value: WinRTComponent.MinimalDelegate?) throws -> WinRTComponent.MinimalDelegate? { value }
        func array(_ value: [String]) throws -> [String] { value }
    }
}