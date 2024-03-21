import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIUnknownIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        let unknownReference1 = try unknown2._queryInterface(IUnknownProjection.self)
        let unknownReference2 = try inspectable2._queryInterface(IUnknownProjection.self)
        XCTAssertEqual(unknownReference1.pointer, unknownReference2.pointer)
    }

    func testIInspectableIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        let inspectableReference1 = try unknown2._queryInterface(IInspectableProjection.self)
        let inspectableReference2 = try inspectable2._queryInterface(IInspectableProjection.self)
        XCTAssertEqual(inspectableReference1.pointer, inspectableReference2.pointer)
    }

    func testQueryInterfaceTransitivityRule() throws {
        let swiftObject = SwiftObject()
        let unknown = try swiftObject.queryInterface(IUnknownProjection.self)
        let inspectable = try swiftObject.queryInterface(IInspectableProjection.self)
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        // QueryInterface should succeed from/to any pair of implemented interfaces
        let objects: [any IUnknownProtocol] = [unknown, inspectable, unknown2, inspectable2]
        for object in objects {
            _ = try object.queryInterface(IUnknownProjection.self)
            _ = try object.queryInterface(IInspectableProjection.self)
            _ = try object.queryInterface(IUnknown2Projection.self)
            _ = try object.queryInterface(IInspectable2Projection.self)
        }
    }

    func testIAgileObject() throws {
        final class AgileObject: WinRTExport<IInspectableProjection> {
            override class var implementIAgileObject: Bool { true }
        }

        final class NonAgileObject: WinRTExport<IInspectableProjection> {
            override class var implementIAgileObject: Bool { false }
        }

        let _ = try AgileObject().queryInterface(IAgileObjectProjection.self)
        XCTAssertThrowsError(try NonAgileObject().queryInterface(IAgileObjectProjection.self))
    }

    func testIStringable() throws {
        final class Stringable: WinRTExport<IInspectableProjection>, CustomStringConvertible {
            var description: String { "hello" }
        }

        XCTAssertEqual(try Stringable().queryInterface(IStringableProjection.self).toString(), "hello")
    }

    func testIWeakReferenceSource() throws {
        final class WeakReferenceSource: WinRTExport<IInspectableProjection> {
            override class var implementIWeakReferenceSource: Bool { true }
        }

        final class NonWeakReferenceSource: WinRTExport<IInspectableProjection> {
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