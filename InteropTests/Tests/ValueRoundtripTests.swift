import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed as arguments from Swift into WinRT,
/// and returned from WinRT into Swift, without loss of information.
class ValueRoundtripTests: WinRTTestCase {
    private var passthrough: IPassthrough!

    override func setUpWithError() throws {
        try super.setUpWithError()
        passthrough = try Passthrough.create()
    }

    override func tearDownWithError() throws {
        passthrough = nil
        try super.tearDownWithError()
    }

    func testInt32() throws {
        XCTAssertEqual(try passthrough.int32(42), 42)
    }

    func testString() throws {
        XCTAssertEqual(try passthrough.string("foo"), "foo")
    }

    func testObject() throws {
        let original: IInspectable = try MinimalClass()
        let roundtripped = try XCTUnwrap(passthrough.object(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testEnum() throws { XCTAssertEqual(try passthrough.enum(.value), .value) }

    func testStruct() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try passthrough.struct(original), original)
    }

    func testInterface() throws {
        let original: IMinimalInterface = try MinimalClass()
        let roundtripped = try XCTUnwrap(passthrough.interface(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testClass() throws {
        let instance = try MinimalClass()
        XCTAssertEqual(
            try XCTUnwrap(passthrough.class(instance)).comPointer,
            instance.comPointer)
    }

    func testDelegate() throws { throw XCTSkip("Delegates are not yet implemented") }
}