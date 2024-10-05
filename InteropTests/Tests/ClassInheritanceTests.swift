import COM
import XCTest
import WindowsRuntime
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
        class SwiftDerived: MinimalBaseClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override func _typeName() throws -> String { "SwiftDerived" }
        }

        XCTAssertEqual(try SwiftDerived()._typeName(), "SwiftDerived")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(SwiftDerived()), "SwiftDerived")
    }

    public func testOverridenMemberInSwiftClassDerivedFromWinRTDerivedClass() throws {
        class SwiftDerived2: MinimalDerivedClass, @unchecked Sendable {
            public override init() throws { try super.init() }
            public override func _typeName() throws -> String { "SwiftDerived2" }
        }

        XCTAssertEqual(try SwiftDerived2()._typeName(), "SwiftDerived2")
        XCTAssertEqual(try MinimalBaseClass.getTypeName(SwiftDerived2()), "SwiftDerived2")
    }

    public func testNoUpcasting() throws {
        XCTAssertNil(try MinimalBaseClass.createDerivedAsBase() as? MinimalDerivedClass)
    }

    public func testWithUpcasting() throws {
        struct UpcastingSwiftWrapperFactory: SwiftWrapperFactory {
            func create<Binding: COMBinding>(
                    _ reference: consuming Binding.ABIReference,
                    binding: Binding.Type) -> Binding.SwiftObject {
                // Try from the runtime type first, then fall back to the statically known binding
                if let object: Binding.SwiftObject = fromRuntimeType(
                        inspectable: IInspectablePointer(OpaquePointer(reference.pointer))) {
                    return object
                } else {
                    return Binding._wrap(consume reference)
                }
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

            func fromRuntimeType<SwiftObject>(inspectable: IInspectablePointer) -> SwiftObject? {
                guard let runtimeClassName = try? COMInterop(inspectable).getRuntimeClassName() else { return nil }
                let swiftBindingQualifiedName = toBindingQualifiedName(runtimeClassName: consume runtimeClassName)
                guard let bindingType = NSClassFromString(swiftBindingQualifiedName) as? any ComposableClassBinding.Type else { return nil }
                return bindingType._wrapObject(COMReference(addingRef: inspectable)) as? SwiftObject
            }
        }

        let originalFactory = WindowsRuntime.swiftWrapperFactory
        WindowsRuntime.swiftWrapperFactory = UpcastingSwiftWrapperFactory()
        defer { WindowsRuntime.swiftWrapperFactory = originalFactory }

        XCTAssertNotNil(try MinimalBaseClass.createDerivedAsBase() as? MinimalDerivedClass)
    }
}