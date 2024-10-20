import XCTest
@testable import CodeWriters

class SwiftSyntaxWriterTests: XCTestCase {
    func testNewLineInDocumentationComment() throws {
        let writer = SwiftSourceFileWriter(output: "")

        var docs = SwiftDocumentationComment()
        docs.summary = [.paragraph(.text("A\nB"))]
        writer.writeStoredProperty(
            documentation: docs,
            declarator: .let,
            name: "answer",
            initialValue: "42")

        let lines = try XCTUnwrap(writer.output.inner as? String)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
        XCTAssertEqual(lines, [
            "/// A",
            "/// B",
            "let answer = 42"
        ])
    }

    // Regression test for https://github.com/tristanlabelle/swift-winrt/issues/358
    func testDocumentationCommentSpacing() throws {
        let writer = SwiftSourceFileWriter(output: "")

        writer.writeStoredProperty(declarator: .let, name: "first", initialValue: "1")

        var docs = SwiftDocumentationComment()
        docs.summary = [.paragraph(.text("Docs"))]
        writer.writeStoredProperty(documentation: docs, declarator: .let, name: "second", initialValue: "2")

        let lines = try XCTUnwrap(writer.output.inner as? String)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
        XCTAssertEqual(lines, [
            "let first = 1",
            "",
            "/// Docs",
            "let second = 2"
        ])
    }
}