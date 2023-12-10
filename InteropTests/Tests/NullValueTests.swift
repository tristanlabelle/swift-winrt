import XCTest
import WinRTComponent

class NullValueTests: WinRTTestCase {
    func testIsNull() throws {
        let minimalClass = try MinimalClass()
        XCTAssertFalse(try NullValues.isObjectNull(minimalClass))
        XCTAssertTrue(try NullValues.isObjectNull(nil))
        XCTAssertFalse(try NullValues.isInterfaceNull(minimalClass))
        XCTAssertTrue(try NullValues.isInterfaceNull(nil))
        XCTAssertFalse(try NullValues.isClassNull(minimalClass))
        XCTAssertTrue(try NullValues.isClassNull(nil))
        XCTAssertFalse(try NullValues.isDelegateNull({ fatalError() }));
        XCTAssertTrue(try NullValues.isDelegateNull(nil));
    }

    func testGetNull() throws {
        XCTAssertNil(try NullValues.getNullObject())
        XCTAssertNil(try NullValues.getNullInterface())
        XCTAssertNil(try NullValues.getNullDelegate())
        XCTAssertNil(try NullValues.getNullClass())
    }
}