import COM
import XCTest
import WindowsRuntime
import WinRTComponent

class ClassInheritanceTests : XCTestCase {
    public func testOverridableMemberOnBaseClass() throws {
        // Created from Swift
        XCTAssertEqual(try MinimalBaseClass().typeName, "MinimalBaseClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalBaseClass()), "MinimalBaseClass")

        // Created from WinRT
        XCTAssertEqual(try MinimalBaseClassHierarchy.createBase().typeName, "MinimalBaseClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalBaseClassHierarchy.createBase()), "MinimalBaseClass")
    }

    public func testOverridenMemberInUnsealedDerivedClass() throws {
        // Created from Swift
        XCTAssertEqual(try MinimalUnsealedDerivedClass().typeName, "MinimalUnsealedDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalUnsealedDerivedClass()), "MinimalUnsealedDerivedClass")

        // Created from WinRT
        XCTAssertEqual(try MinimalBaseClassHierarchy.createUnsealedDerived().typeName, "MinimalUnsealedDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalBaseClassHierarchy.createUnsealedDerived()), "MinimalUnsealedDerivedClass")
    }

    public func testOverridenMemberInSealedDerivedClass() throws {
        // Created from Swift
        XCTAssertEqual(try MinimalSealedDerivedClass().typeName, "MinimalSealedDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalSealedDerivedClass()), "MinimalSealedDerivedClass")

        // Created from WinRT
        XCTAssertEqual(try MinimalBaseClassHierarchy.createSealedDerived().typeName, "MinimalSealedDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalBaseClassHierarchy.createSealedDerived()), "MinimalSealedDerivedClass")
    }

    public func testOverridenMemberInPrivateDerivedClass() throws {
        XCTAssertEqual(try MinimalBaseClassHierarchy.createPrivateDerived().typeName, "PrivateDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(MinimalBaseClassHierarchy.createPrivateDerived()), "PrivateDerivedClass")
    }

    public func testOverridenMemberInSwiftDerivedClass() throws {
        class SwiftDerivedClass: MinimalBaseClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override var typeName: String { get throws { "SwiftDerivedClass" } }
        }

        XCTAssertEqual(try SwiftDerivedClass().typeName, "SwiftDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(SwiftDerivedClass()), "SwiftDerivedClass")
    }

    public func testOverridenMemberInSwiftClassDerivedFromUnsealedDerivedClass() throws {
        class SwiftDerivedDerivedClass: MinimalUnsealedDerivedClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override var typeName: String { get throws { "SwiftDerivedDerivedClass" } }
        }

        XCTAssertEqual(try SwiftDerivedDerivedClass().typeName, "SwiftDerivedDerivedClass")
        XCTAssertEqual(try MinimalBaseClassHierarchy.getTypeName(SwiftDerivedDerivedClass()), "SwiftDerivedDerivedClass")
    }

    public func testNoUpcasting() throws {
        XCTAssertNil(try MinimalBaseClassHierarchy.createUnsealedDerivedAsBase() as? MinimalUnsealedDerivedClass)
        XCTAssertNil(try MinimalBaseClassHierarchy.createSealedDerivedAsBase() as? MinimalSealedDerivedClass)
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
                // Namespace.ClassName -> WinRTComponent.ClassNameBinding
                var result = runtimeClassName
                if let lastDotIndex = runtimeClassName.lastIndex(of: ".") {
                    result.removeSubrange(...lastDotIndex)
                }
                result.insert(contentsOf: "WinRTComponent.", at: result.startIndex)
                result += "Binding"
                return result
            }
        }

        let originalFactory = WindowsRuntime.swiftWrapperFactory
        WindowsRuntime.swiftWrapperFactory = UpcastableSwiftWrapperFactory()
        defer { WindowsRuntime.swiftWrapperFactory = originalFactory }

        XCTAssertNotNil(try MinimalBaseClassHierarchy.createUnsealedDerivedAsBase() as? MinimalUnsealedDerivedClass)
        XCTAssertNotNil(try MinimalBaseClassHierarchy.createSealedDerivedAsBase() as? MinimalSealedDerivedClass)
    }
}