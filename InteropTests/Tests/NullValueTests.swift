import COM
import XCTest
import WinRTComponent

class NullValueTests: WinRTTestCase {
    func testIsNull() throws {
        let minimalClass = try WinRTComponent_MinimalClass()
        let minimalInterface = try WinRTComponent_MinimalInterfaceFactory.create()
        XCTAssertFalse(try WinRTComponent_NullValues.isObjectNull(minimalClass))
        XCTAssertTrue(try WinRTComponent_NullValues.isObjectNull(nil))
        XCTAssertFalse(try WinRTComponent_NullValues.isInterfaceNull(minimalInterface))
        XCTAssertTrue(try WinRTComponent_NullValues.isInterfaceNull(nil))
        XCTAssertFalse(try WinRTComponent_NullValues.isClassNull(minimalClass))
        XCTAssertTrue(try WinRTComponent_NullValues.isClassNull(nil))
        XCTAssertFalse(try WinRTComponent_NullValues.isDelegateNull({ fatalError() }));
        XCTAssertTrue(try WinRTComponent_NullValues.isDelegateNull(nil));
        XCTAssertFalse(try WinRTComponent_NullValues.isReferenceNull(42));
        XCTAssertTrue(try WinRTComponent_NullValues.isReferenceNull(nil));
    }

    func testGetNull() throws {
        XCTAssertNil(try NullResult.catch(WinRTComponent_NullValues.getNullObject()))
        XCTAssertNil(try NullResult.catch(WinRTComponent_NullValues.getNullInterface()))
        XCTAssertNil(try NullResult.catch(WinRTComponent_NullValues.getNullDelegate()))
        XCTAssertNil(try NullResult.catch(WinRTComponent_NullValues.getNullClass()))
        XCTAssertNil(try WinRTComponent_NullValues.getNullReference())
    }
}