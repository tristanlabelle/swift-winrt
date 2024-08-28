import XCTest
import WindowsRuntime

internal final class IReferenceTests: WinRTTestCase {
    func testCreateNumeric() throws {
        XCTAssertNil(try IReferenceUnboxingProjection.Int32.toABI(nil))
        XCTAssertNil(IReferenceUnboxingProjection.Int32.toSwift(nil))

        var boxed = try IReferenceUnboxingProjection.Int32.toABI(42)
        defer { IReferenceUnboxingProjection.Int32.release(&boxed) }
        XCTAssertEqual(IReferenceUnboxingProjection.Int32.toSwift(boxed), 42)
    }
}