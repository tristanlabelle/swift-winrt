import XCTest
import WinRTComponent
import UWP_WindowsFoundation
import struct Foundation.Date

class DateTimeTests: WinRTTestCase {
    func testTimeSpan() throws {
        XCTAssertEqual(try DateTimes.fromSeconds(42).timeInterval.rounded(), 42)
        XCTAssertEqual(try DateTimes.roundToSeconds(TimeSpan(timeInterval: 42)), 42)
    }

    func testDateTime() throws {
        XCTAssertEqual(try DateTimes.fromUTCYearMonthDay(1970, 1, 1).foundationDate.timeIntervalSince1970, 0)
        var year: Int32 = 0
        var month: Int32 = 0
        var day: Int32 = 0
        try DateTimes.toUTCYearMonthDay(DateTime(foundationDate: Date(timeIntervalSince1970: 0)), &year, &month, &day)
        XCTAssertEqual(year, 1970)
        XCTAssertEqual(month, 1)
        XCTAssertEqual(day, 1)
    }
}