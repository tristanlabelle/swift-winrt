import XCTest
import WinRTComponent

class NullValueTests: WinRTTestCase {
    func testGetNull() throws {
        XCTAssertNil(try NullValues.getNullObject())
        XCTAssertNil(try NullValues.getNullInterface())
        XCTAssertNil(try NullValues.getNullDelegate())
        XCTAssertNil(try NullValues.getNullClass())
    }
}