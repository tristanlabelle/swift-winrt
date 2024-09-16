import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIInspectableIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Binding.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Binding.self)

        let inspectableReference1 = try unknown2._queryInterface(IInspectableBinding.self)
        let inspectableReference2 = try inspectable2._queryInterface(IInspectableBinding.self)
        XCTAssertEqual(inspectableReference1.pointer, inspectableReference2.pointer)
    }

    func testIStringable() throws {
        final class Stringable: WinRTPrimaryExport<IInspectableBinding>, CustomStringConvertible {
            var description: String { "hello" }
        }

        XCTAssertEqual(try Stringable().queryInterface(WindowsFoundation_IStringableBinding.self).toString(), "hello")
    }

    func testIWeakReferenceSource() throws {
        final class WeakReferenceSource: WinRTPrimaryExport<IInspectableBinding> {
            override class var implementIWeakReferenceSource: Bool { true }
        }

        final class NonWeakReferenceSource: WinRTPrimaryExport<IInspectableBinding> {
            override class var implementIWeakReferenceSource: Bool { false }
        }

        var implementIWeakReferenceSource: WeakReferenceSource? = WeakReferenceSource()
        let weakReference: IWeakReference = try implementIWeakReferenceSource!.queryInterface(IWeakReferenceSourceBinding.self).getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        implementIWeakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())

        XCTAssertThrowsError(try NonWeakReferenceSource().queryInterface(IWeakReferenceSourceBinding.self))
    }
}