import COM
import XCTest
import WinRTComponent

class NullValueTests: WinRTTestCase {
    func testIsNull() throws {
        let minimalClass = try MinimalClass()
        let minimalInterface = try MinimalInterfaceFactory.create()
        XCTAssertFalse(try NullValues.isObjectNull(minimalClass))
        XCTAssertTrue(try NullValues.isObjectNull(nil))
        XCTAssertFalse(try NullValues.isInterfaceNull(minimalInterface))
        XCTAssertTrue(try NullValues.isInterfaceNull(nil))
        XCTAssertFalse(try NullValues.isClassNull(minimalClass))
        XCTAssertTrue(try NullValues.isClassNull(nil))
        XCTAssertFalse(try NullValues.isDelegateNull({ fatalError() }));
        XCTAssertTrue(try NullValues.isDelegateNull(nil));
        XCTAssertFalse(try NullValues.isReferenceNull(42));
        XCTAssertTrue(try NullValues.isReferenceNull(nil));
    }

    func testGetNull() throws {
        XCTAssertNil(try NullResult.catch(NullValues.getNullObject()))
        XCTAssertNil(try NullResult.catch(NullValues.getNullInterface()))
        XCTAssertNil(try NullResult.catch(NullValues.getNullDelegate()))
        XCTAssertNil(try NullResult.catch(NullValues.getNullClass()))
        XCTAssertNil(try NullValues.getNullReference())
    }
}