import XCTest
import WindowsRuntime

internal final class IReferenceTests: XCTestCase {
    private static var winRTInitialization: Result<WinRTInitialization, any Error>! = nil

    override class func setUp() {
        winRTInitialization = Result { try WinRTInitialization(multithreaded: false) }
    }

    override func setUpWithError() throws {
        _ = try XCTUnwrap(Self.winRTInitialization).get()
        try super.setUpWithError()
    }

    override class func tearDown() {
        winRTInitialization = nil
    }

    func testCreateNumeric() throws {
        print("1")
        XCTAssertNil(try IReferenceUnboxingProjection.Int32.toABI(nil))
        print("2")
        XCTAssertNil(IReferenceUnboxingProjection.Int32.toSwift(nil))

        print("3")
        var boxed = try IReferenceUnboxingProjection.Int32.toABI(42)
        defer {
            print("5")
            IReferenceUnboxingProjection.Int32.release(&boxed)
        }
        print("4")
        XCTAssertEqual(IReferenceUnboxingProjection.Int32.toSwift(boxed), 42)
    }
}