import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIUnknownIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        let unknownPointer1 = try unknown2._queryInterfacePointer(IUnknownProjection.self)
        defer { unknownPointer1.release() }
        let unknownPointer2 = try inspectable2._queryInterfacePointer(IUnknownProjection.self)
        defer { unknownPointer2.release() }
        XCTAssertEqual(unknownPointer1, unknownPointer2)
    }

    func testIInspectableIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Projection.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Projection.self)

        let inspectablePointer1 = try unknown2._queryInterfacePointer(IInspectableProjection.self)
        defer { IUnknownPointer.release(inspectablePointer1) }
        let inspectablePointer2 = try inspectable2._queryInterfacePointer(IInspectableProjection.self)
        defer { IUnknownPointer.release(inspectablePointer2) }
        XCTAssertEqual(inspectablePointer1, inspectablePointer2)
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
            override class var agile: Bool { true }
        }

        final class NonAgileObject: WinRTExport<IInspectableProjection> {
            override class var agile: Bool { false }
        }

        let _ = try AgileObject().queryInterface(IAgileObjectProjection.self)
        XCTAssertThrowsError(try NonAgileObject().queryInterface(IAgileObjectProjection.self))
    }

    func testIWeakReferenceSource() throws {
        final class WeakReferenceSource: WinRTExport<IInspectableProjection> {
            override class var weakReferenceSource: Bool { true }
        }

        final class NonWeakReferenceSource: WinRTExport<IInspectableProjection> {
            override class var weakReferenceSource: Bool { false }
        }

        var weakReferenceSource: WeakReferenceSource? = WeakReferenceSource()
        let weakReference: IWeakReference = try weakReferenceSource!.queryInterface(IWeakReferenceSourceProjection.self).getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        weakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())

        XCTAssertThrowsError(try NonWeakReferenceSource().queryInterface(IWeakReferenceSourceProjection.self))
    }
}