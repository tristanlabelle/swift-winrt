import XCTest
import WindowsRuntime

internal final class HStringTests: XCTestCase {
    func testEmptyString() throws {
        XCTAssertNil(try HString.create("").detach())
        XCTAssertEqual(HString.toString(nil), "")
    }

    func testRoundTrip() throws {
        func assertRoundTrip(_ str: String) throws{
            let roundtripped = try HString.create(str).toString()
            XCTAssertEqual(str, roundtripped)
        }

        try assertRoundTrip("")
        try assertRoundTrip("a")
        try assertRoundTrip("à")
        try assertRoundTrip("☃")
    }
}