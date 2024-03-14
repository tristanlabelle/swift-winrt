import COM
import XCTest
import WinRTComponent

class CompositionTests : XCTestCase {
    class Derived: MinimalUnsealedClass {
        public override init() throws { try super.init() }
        public override var isDerived: Bool { get throws { true } }
    }

    public func testDerived() throws {
        XCTAssertFalse(try MinimalUnsealedClass().isDerived)
        XCTAssertFalse(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass()))
        XCTAssert(try Derived().isDerived)
        XCTAssert(try MinimalUnsealedClass.getIsDerived(Derived()))

        XCTAssertFalse(try MinimalUnsealedClass.create().isDerived)
        XCTAssertFalse(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass.create()))
        XCTAssert(try MinimalUnsealedClass.createDerived().isDerived)
        XCTAssert(try MinimalUnsealedClass.getIsDerived(MinimalUnsealedClass.createDerived()))
    }
}