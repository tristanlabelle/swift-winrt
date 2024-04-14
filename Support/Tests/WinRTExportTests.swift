import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIInspectableIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        let inspectableReference1 = try unknown2._queryInterface(IInspectableProjection.self)
        let inspectableReference2 = try inspectable2._queryInterface(IInspectableProjection.self)
        XCTAssertEqual(inspectableReference1.pointer, inspectableReference2.pointer)
    }

    func testIStringable() throws {
        final class Stringable: WinRTPrimaryExport<IInspectableProjection>, CustomStringConvertible {
            var description: String { "hello" }
        }

        XCTAssertEqual(try Stringable().queryInterface(WindowsFoundation_IStringableProjection.self).toString(), "hello")
    }

    func testIWeakReferenceSource() throws {
        final class WeakReferenceSource: WinRTPrimaryExport<IInspectableProjection> {
            override class var implementIWeakReferenceSource: Bool { true }
        }

        final class NonWeakReferenceSource: WinRTPrimaryExport<IInspectableProjection> {
            override class var implementIWeakReferenceSource: Bool { false }
        }

        var implementIWeakReferenceSource: WeakReferenceSource? = WeakReferenceSource()
        let weakReference: IWeakReference = try implementIWeakReferenceSource!.queryInterface(IWeakReferenceSourceProjection.self).getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        implementIWeakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())

        XCTAssertThrowsError(try NonWeakReferenceSource().queryInterface(IWeakReferenceSourceProjection.self))
    }
}