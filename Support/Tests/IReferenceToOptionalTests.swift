import XCTest
import WindowsRuntime

internal final class IReferenceToOptionalTests: WinRTTestCase {
    func testCreateNumeric() throws {
        XCTAssertNil(try Int32Projection.IReferenceToOptional.toABI(nil))
        XCTAssertNil(Int32Projection.IReferenceToOptional.toSwift(nil))

        var boxed = try Int32Projection.IReferenceToOptional.toABI(42)
        defer { Int32Projection.IReferenceToOptional.release(&boxed) }
        XCTAssertEqual(Int32Projection.IReferenceToOptional.toSwift(boxed), 42)
    }
}