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

    func testMultipleLines() throws {
        let stream = TextDocumentOutputStream(inner: "")
        stream.writeFullLine("foo")
        stream.writeFullLine("bar")
        XCTAssertEqual(
            try XCTUnwrap(stream.inner as? String).split(separator: "\n", omittingEmptySubsequences: false),
            [ "foo", "bar" ])
    }

    func testLineGrouping() throws {
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
        XCTAssertEqual(
            try XCTUnwrap(stream.inner as? String).split(separator: "\n", omittingEmptySubsequences: false),
            [
                "d",
                "d",
                "",
                "a",
                "a",
                "",
                "b",
                "b",
                "",
                "d",
                "d",
                "",
                "n",
                "",
                "n",
                "",
                "d",
                "d"
            ])
    }

    func testLineBlock() throws {
        let stream = TextDocumentOutputStream(inner: "", defaultBlockLinePrefix: "  ")
        stream.writeLineBlock(header: "{", footer: "}") {
            stream.writeFullLine("foo")
            stream.writeFullLine(grouping: .withName("b"), "bar")
        }
        XCTAssertEqual(
            try XCTUnwrap(stream.inner as? String).split(separator: "\n", omittingEmptySubsequences: false),
            [
                "{",
                "  foo",
                "",
                "  bar",
                "}"
            ])
    }

    func testLineBlockGrouping() throws {
        let stream = TextDocumentOutputStream(inner: "", defaultBlockLinePrefix: "  ")
        stream.writeLineBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("a")
        }
        stream.writeLineBlock(grouping: .withName("1"), header: "{", footer: "}") {
            stream.writeFullLine("b")
        }
        stream.writeLineBlock(grouping: .withName("2"), header: "{", footer: "}") {
            stream.writeFullLine("c")
        }
        XCTAssertEqual(
            try XCTUnwrap(stream.inner as? String).split(separator: "\n", omittingEmptySubsequences: false),
            [
                "{",
                "  a",
                "}",
                "{",
                "  b",
                "}",
                "",
                "{",
                "  c",
                "}"
            ])
    }
}