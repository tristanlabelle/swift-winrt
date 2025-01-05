import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class OverloadingTests: WinRTTestCase {
    func testOverloading() throws {
        XCTAssertEqual(try WinRTComponent_OverloadedSum.of(), 0)
        XCTAssertEqual(try WinRTComponent_OverloadedSum.of(42), 42)
        XCTAssertEqual(try WinRTComponent_OverloadedSum.of(7, 3), 10)
    }
}