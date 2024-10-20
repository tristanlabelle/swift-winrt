import XCTest
@testable import CodeWriters

class LineBasedTextOutputStreamTests: XCTestCase {
    func testSingleNonEndedLine() {
        let stream = LineBasedTextOutputStream(inner: "")
        stream.write("Hello, world!")
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testSingleEndedLine() {
        let stream = LineBasedTextOutputStream(inner: "")
        stream.write("Hello, world!", endLine: true)
        XCTAssertEqual(stream.inner as? String, "Hello, world!")
    }

    func testMultipleLines() throws {
        let stream = LineBasedTextOutputStream(inner: "")
        stream.writeFullLine("foo")
        stream.writeFullLine("bar")
        XCTAssertEqual(
            try XCTUnwrap(stream.inner as? String).split(separator: "\n", omittingEmptySubsequences: false),
            [ "foo", "bar" ])
    }

    func testLineGroup() throws {
        let stream = LineBasedTextOutputStream(inner: "")
        stream.writeFullLine("d")
        stream.writeFullLine("d")
        stream.writeFullLine(group: .named("a"), "a")
        stream.writeFullLine(group: .named("a"), "a")
        stream.writeFullLine(group: .named("b"), "b")
        stream.writeFullLine(group: .named("b"), "b")
        stream.writeFullLine("d")
        stream.writeFullLine("d")
        stream.writeFullLine(group: .alone, "n")
        stream.writeFullLine(group: .alone, "n")
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
        let stream = LineBasedTextOutputStream(inner: "", defaultBlockLinePrefix: "  ")
        stream.writeLineBlock(header: "{", footer: "}") {
            stream.writeFullLine("foo")
            stream.writeFullLine(group: .named("b"), "bar")
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
        let stream = LineBasedTextOutputStream(inner: "", defaultBlockLinePrefix: "  ")
        stream.writeLineBlock(group: .named("1"), header: "{", footer: "}") {
            stream.writeFullLine("a")
        }
        stream.writeLineBlock(group: .named("1"), header: "{", footer: "}") {
            stream.writeFullLine("b")
        }
        stream.writeLineBlock(group: .named("2"), header: "{", footer: "}") {
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