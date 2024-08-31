import XCTest
import WindowsRuntime

internal final class IReferenceToOptionalTests: WinRTTestCase {
    func testCreateNumeric() throws {
        XCTAssertNil(try PrimitiveProjection.Int32.IReferenceToOptional.toABI(nil))
        XCTAssertNil(PrimitiveProjection.Int32.IReferenceToOptional.toSwift(nil))

        var boxed = try PrimitiveProjection.Int32.IReferenceToOptional.toABI(42)
        defer { PrimitiveProjection.Int32.IReferenceToOptional.release(&boxed) }
        XCTAssertEqual(PrimitiveProjection.Int32.IReferenceToOptional.toSwift(boxed), 42)
    }
}