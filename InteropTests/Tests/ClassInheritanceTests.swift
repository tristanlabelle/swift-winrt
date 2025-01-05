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
        struct UpcastableSwiftWrapperFactory: SwiftWrapperFactory {
            func create<StaticBinding: COMBinding>(
                    _ reference: consuming StaticBinding.ABIReference,
                    staticBinding: StaticBinding.Type) -> StaticBinding.SwiftObject {
                // Try from the runtime type first, then fall back to the statically known binding
                if let object: StaticBinding.SwiftObject = fromRuntimeType(
                        inspectable: IInspectablePointer(OpaquePointer(reference.pointer))) {
                    return object
                } else {
                    return StaticBinding._wrap(consume reference)
                }
            }

            func fromRuntimeType<SwiftObject>(inspectable: IInspectablePointer) -> SwiftObject? {
                guard let runtimeClassName = try? COMInterop(inspectable).getRuntimeClassName() else { return nil }
                let swiftBindingQualifiedName = toBindingQualifiedName(runtimeClassName: consume runtimeClassName)
                guard let bindingType = NSClassFromString(swiftBindingQualifiedName) as? any RuntimeClassBinding.Type else { return nil }
                return try? bindingType._wrapObject(COMReference(addingRef: inspectable)) as? SwiftObject
            }

            func toBindingQualifiedName(runtimeClassName: String) -> String {
                // Name.Space.ClassName -> WinRTComponent.NameSpace_ClassNameBinding
                var result = runtimeClassName.replace(".", "_")
                if let lastDotIndex = runtimeClassName.lastIndex(of: ".") {
                    result = result.replacingCharacters(in: lastDotIndex...lastDotIndex, with: "_")
                }
                result = result.replacingOccurrences(of: ".", with: "")
                result.insert(contentsOf: "WinRTComponent.", at: result.startIndex)
                result += "Binding"
                return result
            }
        }

        let originalFactory = WindowsRuntime.swiftWrapperFactory
        WindowsRuntime.swiftWrapperFactory = UpcastableSwiftWrapperFactory()
        defer { WindowsRuntime.swiftWrapperFactory = originalFactory }

        XCTAssertNotNil(try WinRTComponent_MinimalBaseClassHierarchy.createUnsealedDerivedAsBase() as? WinRTComponent_MinimalUnsealedDerivedClass)
        XCTAssertNotNil(try WinRTComponent_MinimalBaseClassHierarchy.createSealedDerivedAsBase() as? WinRTComponent_MinimalSealedDerivedClass)
    }
}