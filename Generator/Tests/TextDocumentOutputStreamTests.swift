import XCTest
@testable import CodeWriters

class TextDocumentOutputStreamTests: XCTestCase {
    func testSingleNonEndedLine() {
        let stream = TextDocumentOutputStream(inner: "")
        stream.write("Hello, world!")
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testSingleEndedLine() {
        let stream = TextDocumentOutputStream(inner: "")
        stream.write("Hello, world!", endLine: true)
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testMultipleLines() {
        let stream = TextDocumentOutputStream(inner: "")
        stream.writeFullLine("foo")
        stream.writeFullLine("bar")
        XCTAssertEqual(stream.inner as? String, "foo\nbar")
    }

    func testLineGrouping() {
        let stream = TextDocumentOutputStream(inner: "")
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
        let stream = TextDocumentOutputStream(inner: "", defaultLinePrefixIncrement: "  ")
        stream.writeLinePrefixedBlock(header: "{", footer: "}") {
            stream.writeFullLine("foo")
            stream.writeFullLine(grouping: .withName("b"), "bar")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  foo\n\n  bar\n}")
    }

    func testIndentedBlockGrouping() {
        let stream = TextDocumentOutputStream(inner: "", defaultLinePrefixIncrement: "  ")
        stream.writeLinePrefixedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("a")
        }
        stream.writeLinePrefixedBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("b")
        }
        stream.writeLinePrefixedBlock(grouping: .withName("2"), header: "{", footer: "}") {
            stream.writeFullLine("c")
        }
        XCTAssertEqual(stream.inner as? String, "{\n  a\n}\n{\n  b\n}\n\n{\n  c\n}")
    }
}