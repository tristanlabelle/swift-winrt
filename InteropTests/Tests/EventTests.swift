import XCTest
import WinRTComponent

class EventTests: WinRTTestCase {
    func testConsuming() throws {
        let eventSource = try XCTUnwrap(Events.createSource())

        var count = 0
        var registration = try eventSource.event { count += 1 }

        XCTAssertEqual(count, 0)
        try eventSource.fire()
        XCTAssertEqual(count, 1)

        try registration.remove()
        try eventSource.fire()
        XCTAssertEqual(count, 1)
    }
}