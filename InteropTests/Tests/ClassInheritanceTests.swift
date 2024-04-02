import COM
import XCTest
import WinRTComponent

class ClassInheritanceTests : XCTestCase {
    public func testOverridableMemberOnBaseClass() throws {
        // Created from Swift
        XCTAssertEqual(try MinimalBaseClass()._typeName(), "MinimalBaseClass")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(MinimalBaseClass()), "MinimalBaseClass")

        // Created from WinRT
        XCTAssertEqual(try MinimalBaseClass.createBase()._typeName(), "MinimalBaseClass")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(MinimalBaseClass.createBase()), "MinimalBaseClass")
    }

    public func testOverridenMemberInWinRTDerivedClass() throws {
        // Created from Swift
        XCTAssertEqual(try MinimalDerivedClass()._typeName(), "MinimalDerivedClass")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(MinimalDerivedClass()), "MinimalDerivedClass")

        // Created from WinRT
        XCTAssertEqual(try MinimalDerivedClass.createDerived()._typeName(), "MinimalDerivedClass")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(MinimalDerivedClass.createDerived()), "MinimalDerivedClass")
    }

    public func testOverridenMemberInWinRTPrivateClass() throws {
        XCTAssertEqual(try MinimalBaseClass.createPrivate()._typeName(), "PrivateClass")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(MinimalBaseClass.createPrivate()), "PrivateClass")
    }

    public func testOverridenMemberInSwiftClass() throws {
        class SwiftDerived: MinimalBaseClass {
            public override init() throws { try super.init() }
            public override func _typeName() throws -> String { "SwiftDerived" }
        }

        XCTAssertEqual(try SwiftDerived()._typeName(), "SwiftDerived")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(SwiftDerived()), "SwiftDerived")
    }

    public func testOverridenMemberInSwiftClassDerivedFromWinRTDerivedClass() throws {
        class SwiftDerived2: MinimalDerivedClass {
            public override init() throws { try super.init() }
            public override func _typeName() throws -> String { "SwiftDerived2" }
        }

        XCTAssertEqual(try SwiftDerived2()._typeName(), "SwiftDerived2")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(SwiftDerived2()), "SwiftDerived2")
    }
}