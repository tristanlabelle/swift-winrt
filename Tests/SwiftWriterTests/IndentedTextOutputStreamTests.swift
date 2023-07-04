import XCTest
@testable import SwiftWriter

class IndentedTextOutputStreamTests: XCTestCase {
    func testSingleNonEndedLine() {
        let stream = IndentedTextOutputStream(inner: "")
        stream.write("Hello, world!")
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testSingleEndedLine() {
        let stream = IndentedTextOutputStream(inner: "")
        stream.write("Hello, world!", endLine: true)
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testMultipleLines() {
        let stream = IndentedTextOutputStream(inner: "")
        stream.writeLine("foo")
        stream.writeLine("bar")
        XCTAssertEqual(stream.inner as? String, "foo\nbar")
    }

    func testLineGrouping() {
        let stream = IndentedTextOutputStream(inner: "")
        stream.writeLine("d")
        stream.writeLine("d")
        stream.writeLine(grouping: .withName("a"), "a")
        stream.writeLine(grouping: .withName("a"), "a")
        stream.writeLine(grouping: .withName("b"), "b")
        stream.writeLine(grouping: .withName("b"), "b")
        stream.writeLine("d")
        stream.writeLine("d")
        stream.writeLine(grouping: .never, "n")
        stream.writeLine(grouping: .never, "n")
        stream.writeLine("d")
        stream.writeLine("d")
        XCTAssertEqual(stream.inner as? String, [ "d\nd", "a\na", "b\nb", "d\nd", "n", "n", "d\nd" ].joined(separator: "\n\n"))
    }

    func testIndentedBlock() {
        let stream = IndentedTextOutputStream(inner: "", indent: "  ")
        stream.writeIndentedBlock(header: "{", footer: "}") {
            stream.writeLine("foo")
            stream.writeLine(grouping: .withName("b"), "bar")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  foo\n\n  bar\n}")
    }

    func testIndentedBlockGrouping() {
        let stream = IndentedTextOutputStream(inner: "", indent: "  ")
        stream.writeIndentedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeLine("a")
        }
        stream.writeIndentedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeLine("b")
        }
        stream.writeIndentedBlock(grouping: .withName("2"), header: "{", footer: "}") {
            stream.writeLine("c")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  a\n}\n{\n  b\n}\n\n{\n  c\n}")
    }
}