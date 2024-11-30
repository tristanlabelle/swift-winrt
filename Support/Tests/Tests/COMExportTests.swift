import XCTest
import WindowsRuntime

internal final class COMExportTests: XCTestCase {
    final class TestObject: COMPrimaryExport<IUnknownBinding>, ICOMTestProtocol, ICOMTest2Protocol {
        override class var implements: [COMImplements] { [
            .init(ICOMTestBinding.self),
            .init(ICOMTest2Binding.self)
        ] }

        func comTest() throws {}
        func comTest2() throws {}
    }

    func testIUnknownIdentityRule() throws {
        let testObject = TestObject()
        let comTest = try testObject.queryInterface(ICOMTestBinding.self)
        let comTest2 = try testObject.queryInterface(ICOMTest2Binding.self)

        let unknownReference1 = try comTest._queryInterface(IUnknownBinding.self)
        let unknownReference2 = try comTest2._queryInterface(IUnknownBinding.self)
        XCTAssertEqual(unknownReference1.pointer, unknownReference2.pointer)
    }

    func testQueryInterfaceTransitivityRule() throws {
        let testObject = TestObject()
        let unknown = try testObject.queryInterface(IUnknownBinding.self)
        let comTest = try testObject.queryInterface(ICOMTestBinding.self)
        let comTest2 = try testObject.queryInterface(ICOMTest2Binding.self)

        // QueryInterface should succeed from/to any pair of implemented interfaces
        let objects: [any IUnknownProtocol] = [unknown, comTest, comTest2]
        for object in objects {
            _ = try object.queryInterface(IUnknownBinding.self)
            _ = try object.queryInterface(ICOMTestBinding.self)
            _ = try object.queryInterface(ICOMTest2Binding.self)
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

    func testImplementsSecondaryInterface() throws {
        final class CallCounter: COMPrimaryExport<IUnknownBinding>, ICOMTestProtocol {
            override class var implements: [COMImplements] { [
                .init(ICOMTestBinding.self)
            ] }

            var count: Int = 0
            func comTest() throws { count += 1 }
        }

        let callCounter = CallCounter()
        do {
            let comTestReference = try callCounter._queryInterface(ICOMTestBinding.self)
            XCTAssertEqual(callCounter.count, 0)
            try comTestReference.interop.comTest()
        }
        XCTAssertEqual(callCounter.count, 1)
    }
}