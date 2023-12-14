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
        func testChar(codeUnit: UTF16.CodeUnit) throws {
            let char = WideChar(codeUnit: codeUnit)
            XCTAssertEqual(try Strings.roundtripChar(char), char)
        }

        try testChar(codeUnit: 65) // ascii 'a'
        try testChar(codeUnit: 0) // NUL
        try testChar(codeUnit: 0x0142) // non-ascii 'Ł'
        try testChar(codeUnit: 0xE000) // private use
        try testChar(codeUnit: 0xDC00) // low surrogate
        try testChar(codeUnit: 0xD800) // high surrogate
    }

    func testMalformedUTF16() throws {
        XCTAssertEqual(
            try Strings.fromChars([WideChar(codeUnit: 0xDC00)]), // Mismatched low surrogate
            "�") // U+FFFD REPLACEMENT CHARACTER
    }
}