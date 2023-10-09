import XCTest
import COM

internal final class HResultTests: XCTestCase {
    func testMessageHasNoTrailingWhitespace() throws {
        guard let message = HResult.ok.message else { throw XCTSkip("No message was available") }
        guard let lastChar = message.last else { throw XCTSkip("Message was empty") }
        XCTAssert(!lastChar.isWhitespace)
    }
}