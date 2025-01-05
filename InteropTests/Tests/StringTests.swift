import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class StringTests: WinRTTestCase {
    func testEmpty() throws {
        XCTAssertEqual(try WinRTComponent_Strings.roundtrip(""), "")
    }

    func testEmbeddedNull() throws {
        XCTAssertEqual(try WinRTComponent_Strings.roundtrip("\0"), "\0")
    }

    func testNonBasicMultilingualPlane() throws {
        XCTAssertEqual(try WinRTComponent_Strings.roundtrip("😂"), "😂") // U+1F602 FACE WITH TEARS OF JOY
    }

    func testChars() throws {
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(65)), Char16(65)) // ascii 'a'
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(0)), Char16(0)) // NUL
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(0x0142)), Char16(0x0142)) // non-ascii 'Ł'
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(0xE000)), Char16(0xE000)) // private use
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(0xDC00)), Char16(0xDC00)) // low surrogate
        XCTAssertEqual(try WinRTComponent_Strings.roundtripChar(Char16(0xD800)), Char16(0xD800)) // high surrogate
    }

    func testMalformedUTF16() throws {
        XCTAssertEqual(
            try WinRTComponent_Strings.fromChars([Char16(0xDC00)]), // Mismatched low surrogate
            "�") // U+FFFD REPLACEMENT CHARACTER
    }
}