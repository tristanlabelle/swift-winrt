import XCTest
import COM
import WinRTComponent

class StringTests: WinRTTestCase {
    func testEmpty() throws {
        XCTAssertEqual(try Strings.roundtrip(""), "")
    }

    func testEmbeddedNull() throws {
        XCTAssertEqual(try Strings.roundtrip("\0"), "\0")
    }

    func testNonBasicMultilingualPlane() throws {
        XCTAssertEqual(try Strings.roundtrip("😂"), "😂") // U+1F602 FACE WITH TEARS OF JOY
    }

    func testChars() throws {
        XCTAssertEqual(try Strings.roundtripChar(65), 65) // ascii 'a'
        XCTAssertEqual(try Strings.roundtripChar(0), 0) // NUL
        XCTAssertEqual(try Strings.roundtripChar(0x0142), 0x0142) // non-ascii 'Ł'
        XCTAssertEqual(try Strings.roundtripChar(0xE000), 0xE000) // private use
        XCTAssertEqual(try Strings.roundtripChar(0xDC00), 0xDC00) // low surrogate
        XCTAssertEqual(try Strings.roundtripChar(0xD800), 0xD800) // high surrogate
    }

    func testMalformedUTF16() throws {
        XCTAssertEqual(
            try Strings.fromChars([0xDC00]), // Mismatched low surrogate
            "�") // U+FFFD REPLACEMENT CHARACTER
    }
}