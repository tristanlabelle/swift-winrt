import XCTest
@testable import CodeWriters

class SwiftSyntaxWriterTests: XCTestCase {
    func testNewLineInDocumentationComment() throws {
        let stream = LineBasedTextOutputStream(inner: "")
        let writer = SwiftSourceFileWriter(output: stream)

        var docs = SwiftDocumentationComment()
        docs.summary = [.paragraph(.text("A\nB"))]
        writer.writeStoredProperty(
            documentation: docs,
            declarator: .let,
            name: "answer",
            initialValue: "42")

        let lines = try XCTUnwrap(stream.inner as? String)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { String($0) }
        XCTAssertEqual(lines, [
            "/// A",
            "/// B",
            "let answer = 42"
        ])
    }
}