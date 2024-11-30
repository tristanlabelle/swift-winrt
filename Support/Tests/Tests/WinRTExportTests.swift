import XCTest
import WindowsRuntime

internal final class WinRTExportTests: XCTestCase {
    func testIInspectableIdentityRule() throws {
        final class TestObject: WinRTPrimaryExport<IInspectableBinding>, ICOMTestProtocol, IWinRTTestProtocol {
            override class var implements: [COMImplements] { [
                .init(ICOMTestBinding.self),
                .init(IWinRTTestBinding.self)
            ] }

            func comTest() throws {}
            func winRTTest() throws {}
        }

        let testObject = TestObject()
        let comTest = try testObject.queryInterface(ICOMTestBinding.self)
        let winRTTest = try testObject.queryInterface(IWinRTTestBinding.self)

        let inspectableReference1 = try comTest._queryInterface(IInspectableBinding.self)
        let inspectableReference2 = try winRTTest._queryInterface(IInspectableBinding.self)
        XCTAssertEqual(inspectableReference1.pointer, inspectableReference2.pointer)
    }

    func testGetIids() throws {
        final class TestObject: WinRTPrimaryExport<IInspectableBinding>, ICOMTestProtocol, IWinRTTestProtocol {
            override class var implements: [COMImplements] { [
                .init(ICOMTestBinding.self),
                .init(IWinRTTestBinding.self)
            ] }

            func comTest() throws {}
            func winRTTest() throws {}
        }

        let iids = try TestObject().getIids()
        // https://learn.microsoft.com/en-us/windows/win32/api/inspectable/nf-inspectable-iinspectable-getiids:
        // "The IUnknown and IInspectable interfaces are excluded."
        XCTAssertTrue(iids.contains(ICOMTestBinding.interfaceID), "ICOMTest")
        XCTAssertTrue(iids.contains(IWinRTTestBinding.interfaceID), "IWinRTTest")
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