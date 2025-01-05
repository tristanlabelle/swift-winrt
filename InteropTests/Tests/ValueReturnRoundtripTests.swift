import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed without loss of information
/// between Swift and WinRT as arguments and return values.
class ValueReturnRoundtripTests: WinRTTestCase {
    private var oneWay: WinRTComponent_IReturnArgument!
    private var twoWay: WinRTComponent_IReturnArgument!

    override func setUpWithError() throws {
        try super.setUpWithError()
        oneWay = try XCTUnwrap(WinRTComponent_ReturnArgument.create())
        twoWay = try XCTUnwrap(WinRTComponent_ReturnArgument.createProxy(ReturnArgumentImplementation()))
    }

    override func tearDownWithError() throws {
        twoWay = nil
        oneWay = nil
        try super.tearDownWithError()
    }

    func testInt32() throws {
        XCTAssertEqual(try twoWay.int32(42), 42)
    }

    func testString() throws {
        XCTAssertEqual(try twoWay.string("foo"), "foo")
    }

    func testObject() throws {
        let original: IInspectable = try WinRTComponent_MinimalClass()
        assertCOMIdentical(try twoWay.object(original), original)

        XCTAssertNil(try NullResult.catch(twoWay.object(nil)))
    }

    func testEnum() throws {
        XCTAssertEqual(try twoWay.enum(.one), .one)
    }

    func testStruct() throws {
        let original = WinRTComponent_MinimalStruct(field: 42)
        XCTAssertEqual(try twoWay.struct(original), original)
    }

    func testInterface() throws {
        let original: WinRTComponent_IMinimalInterface = try WinRTComponent_MinimalInterfaceFactory.create()
        assertCOMIdentical(try twoWay.interface(original), original)

        XCTAssertNil(try NullResult.catch(twoWay.interface(nil)))
    }

    func testClass() throws {
        let instance = try WinRTComponent_MinimalClass()
        let roundtripped = try twoWay.class(instance)
        XCTAssertNotIdentical(roundtripped, instance)
        XCTAssertEqual(roundtripped._pointer, instance._pointer)

        XCTAssertNil(try NullResult.catch(twoWay.class(nil)))
    }

    func testDelegate() throws {
        // By design, Swift does not support identity comparisons for closures,
        // so we can only test that the round-tripped closure is still calling the same code.
        var called = false
        let result = try twoWay.delegate({ called = true })
        XCTAssertFalse(called)
        try result()
        XCTAssertTrue(called)

        XCTAssertNil(try NullResult.catch(twoWay.delegate(nil)))
    }

    func testArray_oneWay() throws {
        XCTAssertEqual(try oneWay.array(["a", "b"]), ["a", "b"])
    }

    func testArray_twoWay() throws {
        throw XCTSkip("Two-way array bindings are not implemented yet")
    }

    func testReference() throws {
        XCTAssertEqual(try twoWay.reference(42), 42)
        XCTAssertNil(try twoWay.reference(nil))
    }

    class ReturnArgumentImplementation: WinRTExportBase<IReturnArgumentBinding>, IReturnArgumentProtocol {
        func int32(_ value: Int32) throws -> Int32 { value }
        func string(_ value: String) throws -> String { value }
        func object(_ value: WindowsRuntime.IInspectable?) throws -> WindowsRuntime.IInspectable { try NullResult.unwrap(value) }
        func `enum`(_ value: WinRTComponent_MinimalEnum) throws -> WinRTComponent_MinimalEnum { value }
        func `struct`(_ value: WinRTComponent_MinimalStruct) throws -> WinRTComponent_MinimalStruct { value }
        func interface(_ value: WinRTComponent_IMinimalInterface?) throws -> WinRTComponent_IMinimalInterface { try NullResult.unwrap(value) }
        func `class`(_ value: WinRTComponent_MinimalClass?) throws -> WinRTComponent_MinimalClass { try NullResult.unwrap(value) }
        func delegate(_ value: WinRTComponent_MinimalDelegate?) throws -> WinRTComponent_MinimalDelegate { try NullResult.unwrap(value) }
        func array(_ value: [String]) throws -> [String] { value }
        func reference(_ value: Int32?) throws -> Int32? { value }
    }
}