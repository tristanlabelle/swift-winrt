import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed without loss of information
/// between Swift and WinRT as arguments and output parameters.
class ValueOutParamRoundtripTests: WinRTTestCase {
    private var oneWay: IOutputArgument!
    private var twoWay: IOutputArgument!

    override func setUpWithError() throws {
        try super.setUpWithError()
        oneWay = try XCTUnwrap(OutputArgument.create())
        twoWay = try XCTUnwrap(OutputArgument.createProxy(OutputArgumentImplementation()))
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
        let original: IInspectable = try MinimalClass()
        var roundtripped: IInspectable? = nil
        try twoWay.object(original, &roundtripped)
        assertCOMIdentical(original, try XCTUnwrap(roundtripped))
    }

    func testEnum() throws {
        var roundtripped: MinimalEnum = .init()
        try twoWay.enum(.one, &roundtripped)
        XCTAssertEqual(roundtripped, .one)
    }

    func testStruct() throws {
        let original = MinimalStruct(field: 42)
        var roundtripped: MinimalStruct = .init()
        try twoWay.struct(original, &roundtripped)
        XCTAssertEqual(roundtripped, original)
    }

    func testInterface() throws {
        let original: IMinimalInterface = try MinimalClass()
        var roundtripped: IMinimalInterface? = nil
        try twoWay.interface(original, &roundtripped)
        assertCOMIdentical(original, try XCTUnwrap(roundtripped))
    }

    func testClass() throws {
        let instance = try MinimalClass()
        var roundtripped: MinimalClass? = nil
        try twoWay.class(instance, &roundtripped)
        XCTAssertEqual(try XCTUnwrap(roundtripped).comPointer, instance.comPointer)
    }

    func testDelegate() throws {
        // By design, Swift does not support identity comparisons for closures,
        // so we can only test that the round-tripped closure is still calling the same code.
        var called = false
        var roundtripped: MinimalDelegate? = nil
        try twoWay.delegate({ called = true }, &roundtripped)
        XCTAssertFalse(called)
        try XCTUnwrap(roundtripped)()
        XCTAssertTrue(called)
    }

    func testArray_oneWay() throws {
        var roundtripped: [String] = []
        try oneWay.array(["a", "b"], &roundtripped)
        XCTAssertEqual(roundtripped, ["a", "b"])
    }

    func testArray_twoWay() throws {
        throw XCTSkip("Two-way array projections are not implemented yet")
    }

    class OutputArgumentImplementation: WinRTExport<IOutputArgumentProjection>, IOutputArgumentProtocol {
        func int32(_ value: Int32, _ result: inout Int32) throws { result = value }
        func string(_ value: String, _ result: inout String) throws { result = value }
        func object(_ value: WindowsRuntime.IInspectable?, _ result: inout WindowsRuntime.IInspectable?) throws { result = value }
        func `enum`(_ value: WinRTComponent.MinimalEnum, _ result: inout WinRTComponent.MinimalEnum) throws { result = value }
        func `struct`(_ value: WinRTComponent.MinimalStruct, _ result: inout WinRTComponent.MinimalStruct) throws { result = value }
        func interface(_ value: WinRTComponent.IMinimalInterface?, _ result: inout WinRTComponent.IMinimalInterface?) throws { result = value }
        func `class`(_ value: WinRTComponent.MinimalClass?, _ result: inout WinRTComponent.MinimalClass?) throws { result = value }
        func delegate(_ value: WinRTComponent.MinimalDelegate?, _ result: inout WinRTComponent.MinimalDelegate?) throws { result = value }
        func array(_ value: [String], _ result: inout [String]) throws { result = value }
    }
}