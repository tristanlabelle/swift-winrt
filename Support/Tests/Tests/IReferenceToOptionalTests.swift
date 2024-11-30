import XCTest
import WindowsRuntime

internal final class IReferenceToOptionalTests: WinRTTestCase {
    func testCreateNumeric() throws {
        XCTAssertNil(try Int32Binding.IReferenceToOptional.toABI(nil))
        XCTAssertNil(Int32Binding.IReferenceToOptional.fromABI(nil))

        var boxed = try Int32Binding.IReferenceToOptional.toABI(42)
        defer { Int32Binding.IReferenceToOptional.release(&boxed) }
        XCTAssertEqual(Int32Binding.IReferenceToOptional.fromABI(boxed), 42)
    }
}