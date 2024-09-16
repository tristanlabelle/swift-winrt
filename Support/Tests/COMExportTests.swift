import XCTest
import WindowsRuntime

internal final class COMExportTests: XCTestCase {
    func testIUnknownIdentityRule() throws {
        let swiftObject = SwiftObject()
        let unknown2 = try swiftObject.queryInterface(IUnknown2Binding.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Binding.self)

        let unknownReference1 = try unknown2._queryInterface(IUnknownBinding.self)
        let unknownReference2 = try inspectable2._queryInterface(IUnknownBinding.self)
        XCTAssertEqual(unknownReference1.pointer, unknownReference2.pointer)
    }

    func testQueryInterfaceTransitivityRule() throws {
        let swiftObject = SwiftObject()
        let unknown = try swiftObject.queryInterface(IUnknownBinding.self)
        let inspectable = try swiftObject.queryInterface(IInspectableBinding.self)
        let unknown2 = try swiftObject.queryInterface(IUnknown2Binding.self)
        let inspectable2 = try swiftObject.queryInterface(IInspectable2Binding.self)

        // QueryInterface should succeed from/to any pair of implemented interfaces
        let objects: [any IUnknownProtocol] = [unknown, inspectable, unknown2, inspectable2]
        for object in objects {
            _ = try object.queryInterface(IUnknownBinding.self)
            _ = try object.queryInterface(IInspectableBinding.self)
            _ = try object.queryInterface(IUnknown2Binding.self)
            _ = try object.queryInterface(IInspectable2Binding.self)
        }
    }

    func testIAgileObject() throws {
        final class AgileObject: COMPrimaryExport<IUnknownBinding> {
            override class var implementIAgileObject: Bool { true }
        }

        final class NonAgileObject: COMPrimaryExport<IUnknownBinding> {
            override class var implementIAgileObject: Bool { false }
        }

        let _ = try AgileObject().queryInterface(IAgileObjectBinding.self)
        XCTAssertThrowsError(try NonAgileObject().queryInterface(IAgileObjectBinding.self))
    }

    func testFreeThreadedMarshalability() throws {
        final class Marshalable: COMPrimaryExport<IUnknownBinding> {
            override class var implementFreeThreadedMarshaling: Bool { true }
        }

        final class NonMarshalable: COMPrimaryExport<IUnknownBinding> {
            override class var implementFreeThreadedMarshaling: Bool { false }
        }

        let imarshalID = COMInterfaceID(0x00000003, 0x0000, 0x0000, 0xC000, 0x000000000046)
        let _ = try Marshalable()._queryInterface(imarshalID)
        XCTAssertThrowsError(try { _ = try NonMarshalable()._queryInterface(imarshalID) }())
    }
}