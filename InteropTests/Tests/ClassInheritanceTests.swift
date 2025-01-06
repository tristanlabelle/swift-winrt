import COM
import XCTest
import WindowsRuntime
import WinRTComponent

class ClassInheritanceTests : XCTestCase {
    public func testOverridableMemberOnBaseClass() throws {
        // Created from Swift
        XCTAssertEqual(try WinRTComponent_MinimalBaseClass().typeName, "MinimalBaseClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalBaseClass()), "MinimalBaseClass")

        // Created from WinRT
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.createBase().typeName, "MinimalBaseClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalBaseClassHierarchy.createBase()), "MinimalBaseClass")
    }

    public func testOverridenMemberInUnsealedDerivedClass() throws {
        // Created from Swift
        XCTAssertEqual(try WinRTComponent_MinimalUnsealedDerivedClass().typeName, "MinimalUnsealedDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalUnsealedDerivedClass()), "MinimalUnsealedDerivedClass")

        // Created from WinRT
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.createUnsealedDerived().typeName, "MinimalUnsealedDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalBaseClassHierarchy.createUnsealedDerived()), "MinimalUnsealedDerivedClass")
    }

    public func testOverridenMemberInSealedDerivedClass() throws {
        // Created from Swift
        XCTAssertEqual(try WinRTComponent_MinimalSealedDerivedClass().typeName, "MinimalSealedDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalSealedDerivedClass()), "MinimalSealedDerivedClass")

        // Created from WinRT
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.createSealedDerived().typeName, "MinimalSealedDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalBaseClassHierarchy.createSealedDerived()), "MinimalSealedDerivedClass")
    }

    public func testOverridenMemberInPrivateDerivedClass() throws {
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.createPrivateDerived().typeName, "PrivateDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(WinRTComponent_MinimalBaseClassHierarchy.createPrivateDerived()), "PrivateDerivedClass")
    }

    public func testOverridenMemberInSwiftDerivedClass() throws {
        class SwiftDerivedClass: WinRTComponent_MinimalBaseClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override var typeName: String { get throws { "SwiftDerivedClass" } }
        }

        XCTAssertEqual(try SwiftDerivedClass().typeName, "SwiftDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(SwiftDerivedClass()), "SwiftDerivedClass")
    }

    public func testOverridenMemberInSwiftClassDerivedFromUnsealedDerivedClass() throws {
        class SwiftDerivedDerivedClass: WinRTComponent_MinimalUnsealedDerivedClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override var typeName: String { get throws { "SwiftDerivedDerivedClass" } }
        }

        XCTAssertEqual(try SwiftDerivedDerivedClass().typeName, "SwiftDerivedDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(SwiftDerivedDerivedClass()), "SwiftDerivedDerivedClass")
    }

    public func testOverridenMemberInSwiftDerivedClassWithoutOverrideSupport() throws {
        class SwiftDerivedClass: WinRTComponent_MinimalBaseClass, @unchecked Sendable {
            override class var supportsOverrides: Bool { false }
            public override init() throws { try super.init() }
            public override var typeName: String { get throws { "SwiftDerivedClass" } }
        }

        XCTAssertEqual(try SwiftDerivedClass().typeName, "SwiftDerivedClass")
        XCTAssertEqual(try WinRTComponent_MinimalBaseClassHierarchy.getTypeName(SwiftDerivedClass()), "MinimalBaseClass")
    }

    public func testNoUpcasting() throws {
        XCTAssertNil(try WinRTComponent_MinimalBaseClassHierarchy.createUnsealedDerivedAsBase() as? WinRTComponent_MinimalUnsealedDerivedClass)
        XCTAssertNil(try WinRTComponent_MinimalBaseClassHierarchy.createSealedDerivedAsBase() as? WinRTComponent_MinimalSealedDerivedClass)
    }

    public func testWithUpcasting() throws {
        let originalBindingResolver = WindowsRuntime.inspectableTypeBindingResolver
        WindowsRuntime.inspectableTypeBindingResolver = DefaultInspectableTypeBindingResolver(
            namespacesToModuleNames: ["WinRTComponent": "WinRTComponent"])
        defer { WindowsRuntime.inspectableTypeBindingResolver = originalBindingResolver }

        XCTAssertNotNil(try WinRTComponent_MinimalBaseClassHierarchy.createUnsealedDerivedAsBase() as? WinRTComponent_MinimalUnsealedDerivedClass)
        XCTAssertNotNil(try WinRTComponent_MinimalBaseClassHierarchy.createSealedDerivedAsBase() as? WinRTComponent_MinimalSealedDerivedClass)
    }
}