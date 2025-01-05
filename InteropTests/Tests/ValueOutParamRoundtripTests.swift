import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed without loss of information
/// between Swift and WinRT as arguments and output parameters.
class ValueOutParamRoundtripTests: WinRTTestCase {
    private var oneWay: WinRTComponent_IOutputArgument!
    private var twoWay: WinRTComponent_IOutputArgument!

    override func setUpWithError() throws {
        try super.setUpWithError()
        oneWay = try XCTUnwrap(WinRTComponent_OutputArgument.create())
        twoWay = try XCTUnwrap(WinRTComponent_OutputArgument.createProxy(OutputArgumentImplementation()))
    }

    override func tearDownWithError() throws {
        twoWay = nil
        oneWay = nil
        try super.tearDownWithError()
    }

    func testInt32() throws {
        var roundtripped: Int32 = 0
        try twoWay.int32(42, &roundtripped)
        XCTAssertEqual(roundtripped, 42)
    }

    func testString() throws {
        var roundtripped: String = ""
        try twoWay.string("foo", &roundtripped)
        XCTAssertEqual(roundtripped, "foo")
    }

    func testObject() throws {
        let original: IInspectable = try WinRTComponent_MinimalClass()
        var roundtripped: IInspectable? = nil
        try twoWay.object(original, &roundtripped)
        assertCOMIdentical(original, try XCTUnwrap(roundtripped))
    }

    func testEnum() throws {
        var roundtripped: WinRTComponent_MinimalEnum = .init()
        try twoWay.enum(.one, &roundtripped)
        XCTAssertEqual(roundtripped, .one)
    }

    func testStruct() throws {
        let original = WinRTComponent_MinimalStruct(field: 42)
        var roundtripped: WinRTComponent_MinimalStruct = .init()
        try twoWay.struct(original, &roundtripped)
        XCTAssertEqual(roundtripped, original)
    }

    func testInterface() throws {
        let original: WinRTComponent_IMinimalInterface = try WinRTComponent_MinimalInterfaceFactory.create()
        var roundtripped: WinRTComponent_IMinimalInterface? = nil
        try twoWay.interface(original, &roundtripped)
        assertCOMIdentical(original, try XCTUnwrap(roundtripped))

        try twoWay.interface(nil, &roundtripped)
        XCTAssertNil(roundtripped)
    }

    func testClass() throws {
        let instance = try WinRTComponent_MinimalClass()
        var roundtripped: WinRTComponent_MinimalClass? = nil
        try twoWay.class(instance, &roundtripped)
        XCTAssertNotIdentical(try XCTUnwrap(roundtripped), instance)
        XCTAssertEqual(try XCTUnwrap(roundtripped)._pointer, instance._pointer)

        try twoWay.class(nil, &roundtripped)
        XCTAssertNil(roundtripped)
    }

    func testDelegate() throws {
        // By design, Swift does not support identity comparisons for closures,
        // so we can only test that the round-tripped closure is still calling the same code.
        var called = false
        var roundtripped: WinRTComponent_MinimalDelegate? = nil
        try twoWay.delegate({ called = true }, &roundtripped)
        XCTAssertFalse(called)
        try XCTUnwrap(roundtripped)()
        XCTAssertTrue(called)

        try twoWay.delegate(nil, &roundtripped)
        XCTAssertNil(roundtripped)
    }

    func testArray_oneWay() throws {
        var roundtripped: [String] = []
        try oneWay.array(["a", "b"], &roundtripped)
        XCTAssertEqual(roundtripped, ["a", "b"])
    }

    func testArray_twoWay() throws {
        throw XCTSkip("Two-way array bindings are not implemented yet")
    }

    func testReference() throws {
        var roundtripped: Int32? = nil
        try twoWay.reference(42, &roundtripped)
        XCTAssertEqual(roundtripped, 42)

        try twoWay.reference(nil, &roundtripped)
        XCTAssertNil(roundtripped)
    }

    class OutputArgumentImplementation: WinRTExportBase<WinRTComponent_IOutputArgumentBinding>, WinRTComponent_IOutputArgumentProtocol {
        func int32(_ value: Int32, _ result: inout Int32) throws { result = value }
        func string(_ value: String, _ result: inout String) throws { result = value }
        func object(_ value: WindowsRuntime.IInspectable?, _ result: inout WindowsRuntime.IInspectable?) throws { result = value }
        func `enum`(_ value: WinRTComponent_MinimalEnum, _ result: inout WinRTComponent_MinimalEnum) throws { result = value }
        func `struct`(_ value: WinRTComponent_MinimalStruct, _ result: inout WinRTComponent_MinimalStruct) throws { result = value }
        func interface(_ value: WinRTComponent_IMinimalInterface?, _ result: inout WinRTComponent_IMinimalInterface?) throws { result = value }
        func `class`(_ value: WinRTComponent_MinimalClass?, _ result: inout WinRTComponent_MinimalClass?) throws { result = value }
        func delegate(_ value: WinRTComponent_MinimalDelegate?, _ result: inout WinRTComponent_MinimalDelegate?) throws { result = value }
        func array(_ value: [String], _ result: inout [String]) throws { result = value }
        func reference(_ value: Int32?, _ result: inout Int32?) throws { result = value }
    }
}