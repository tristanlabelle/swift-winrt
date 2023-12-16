import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class OverloadingTests: WinRTTestCase {
    func testOverloading() throws {
        XCTAssertEqual(try Overloading.sum(), 0)
        XCTAssertEqual(try Overloading.sum(42), 42)
        XCTAssertEqual(try Overloading.sum(7, 3), 10)
    }
}