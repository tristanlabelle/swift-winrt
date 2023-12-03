import COM
import XCTest
import WindowsRuntime
import WinRTComponent

/// Tests that values can be passed as arguments from Swift into WinRT,
/// and returned from WinRT into Swift, without loss of information.
class ValueRoundtripTests: WinRTTestCase {
    private var returnArgument: IReturnArgument!

    override func setUpWithError() throws {
        try super.setUpWithError()
        returnArgument = try ReturnArgument.create()
    }

    override func tearDownWithError() throws {
        returnArgument = nil
        try super.tearDownWithError()
    }

    func testInt32() throws {
        XCTAssertEqual(try returnArgument.int32(42), 42)
    }

    func testString() throws {
        XCTAssertEqual(try returnArgument.string("foo"), "foo")
    }

    func testObject() throws {
        let original: IInspectable = try MinimalClass()
        let roundtripped = try XCTUnwrap(returnArgument.object(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testEnum() throws {
        XCTAssertEqual(try returnArgument.enum(.one), .one)
    }

    func testStruct() throws {
        let original = MinimalStruct(field: 42)
        XCTAssertEqual(try returnArgument.struct(original), original)
    }

    func testInterface() throws {
        let original: IMinimalInterface = try MinimalClass()
        let roundtripped = try XCTUnwrap(returnArgument.interface(original))
        assertCOMIdentical(original, roundtripped)
    }

    func testClass() throws {
        let instance = try MinimalClass()
        XCTAssertEqual(
            try XCTUnwrap(returnArgument.class(instance)).comPointer,
            instance.comPointer)
    }

    func testDelegate() throws {
        throw XCTSkip("Delegates are not yet implemented")
    }

    func testArray() throws {
        XCTAssertEqual(try returnArgument.array(["a", "b"]), ["a", "b"])
    }
}