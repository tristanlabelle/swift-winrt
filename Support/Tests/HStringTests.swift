import XCTest
import WindowsRuntime

internal final class HStringTests: XCTestCase {
    func testEmptyString() throws {
        XCTAssertNil(try HStringProjection.toABI(""))
        XCTAssertEqual(HStringProjection.toSwift(nil), "")
    }

    func testRoundTrip() throws {
        func assertRoundTrip(_ str: String) throws{
            var abi = try HStringProjection.toABI(str)
            let roundtripped = HStringProjection.toSwift(consuming: &abi)
            XCTAssertEqual(str, roundtripped)
        }

        try assertRoundTrip("")
        try assertRoundTrip("a")
        try assertRoundTrip("à")
        try assertRoundTrip("☃")
    }
}