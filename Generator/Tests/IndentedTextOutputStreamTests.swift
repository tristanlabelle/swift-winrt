import XCTest
@testable import CodeWriters

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
        stream.writeFullLine("foo")
        stream.writeFullLine("bar")
        XCTAssertEqual(stream.inner as? String, "foo\nbar")
    }

    func testLineGrouping() {
        let stream = IndentedTextOutputStream(inner: "")
        stream.writeFullLine("d")
        stream.writeFullLine("d")
        stream.writeFullLine(grouping: .withName("a"), "a")
        stream.writeFullLine(grouping: .withName("a"), "a")
        stream.writeFullLine(grouping: .withName("b"), "b")
        stream.writeFullLine(grouping: .withName("b"), "b")
        stream.writeFullLine("d")
        stream.writeFullLine("d")
        stream.writeFullLine(grouping: .never, "n")
        stream.writeFullLine(grouping: .never, "n")
        stream.writeFullLine("d")
        stream.writeFullLine("d")
        XCTAssertEqual(stream.inner as? String, [ "d\nd", "a\na", "b\nb", "d\nd", "n", "n", "d\nd" ].joined(separator: "\n\n"))
    }

    func testIndentedBlock() {
        let stream = IndentedTextOutputStream(inner: "", indent: "  ")
        stream.writeIndentedBlock(header: "{", footer: "}") {
            stream.writeFullLine("foo")
            stream.writeFullLine(grouping: .withName("b"), "bar")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  foo\n\n  bar\n}")
    }

    func testIndentedBlockGrouping() {
        let stream = IndentedTextOutputStream(inner: "", indent: "  ")
        stream.writeIndentedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("a")
        }
        stream.writeIndentedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("b")
        }
        stream.writeIndentedBlock(grouping: .withName("2"), header: "{", footer: "}") {
            stream.writeFullLine("c")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  a\n}\n{\n  b\n}\n\n{\n  c\n}")
    }
}