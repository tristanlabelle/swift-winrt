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
        XCTAssertNil(try WindowsFoundation_IReferenceProjection.Int32.toABI(nil))
        XCTAssertNil(WindowsFoundation_IReferenceProjection.Int32.toSwift(nil))

        var boxed = try WindowsFoundation_IReferenceProjection.Int32.toABI(42)
        defer { WindowsFoundation_IReferenceProjection.Int32.release(&boxed) }
        XCTAssertEqual(WindowsFoundation_IReferenceProjection.Int32.toSwift(boxed), 42)
    }
}