import XCTest
import WinRTComponent

class CollectionTests: WinRTTestCase {
    func testIteration() throws {
        let iterable = try Collections.createIterable([3, 2, 1])
        let iterator = try iterable.first()
        XCTAssert(try iterator._hasCurrent())
        XCTAssertEqual(try iterator._current(), 3)
        XCTAssert(try iterator.moveNext())
        XCTAssertEqual(try iterator._current(), 2)
        XCTAssert(try iterator.moveNext())
        XCTAssertEqual(try iterator._current(), 1)
        XCTAssertFalse(try iterator.moveNext())
    }
}