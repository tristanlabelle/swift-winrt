import COM
import XCTest
import WinRTComponent

class CompositionTests : XCTestCase {
    class Derived: MinimalUnsealedClass {
        public override init() throws { try super.init() }
        public override func _isDerived() throws -> Bool { true }
    }

    public func testDerived() throws {
        XCTAssertFalse(try MinimalUnsealedClass()._isDerived())
        XCTAssertFalse(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass()))
        XCTAssert(try Derived()._isDerived())
        XCTAssert(try MinimalUnsealedClass.getIsDerived(Derived()))

        XCTAssertFalse(try MinimalUnsealedClass.create()._isDerived())
        XCTAssertFalse(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass.create()))
        XCTAssert(try MinimalUnsealedClass.createDerived()._isDerived())
        XCTAssert(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass.createDerived()))
    }
}