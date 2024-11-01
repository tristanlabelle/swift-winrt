import XCTest
import WindowsRuntime
import WinRTComponent

class ObjectExportingTests: WinRTTestCase {
    class ExportedClass: WinRTPrimaryExport<IInspectableBinding> {}

    func testBalancedAddRefRelease() throws {
        let obj: ExportedClass = .init()
        let referencer = try ObjectReferencer(obj)
        let postAddRefCount = try referencer.callAddRef()
        XCTAssert(postAddRefCount > 1)
        let postReleaseRefCount = try referencer.callRelease()
        XCTAssertEqual(postReleaseRefCount, postAddRefCount - 1)
    }

    func testReleaseFromWinRT() throws {
        var obj: ExportedClass? = ExportedClass()
        weak var weakObj = obj
        XCTAssertNotNil(weakObj)

        var referencer: ObjectReferencer? = try ObjectReferencer(obj)
        XCTAssertNotNil(weakObj)

        obj = withExtendedLifetime(obj) { nil } // We should now only be kept alive by WinRT
        XCTAssertNotNil(weakObj)

        referencer = withExtendedLifetime(referencer) { nil }
        XCTAssertNil(weakObj)
    }

    func testUnwrapping() throws {
        let obj: IInspectable = ExportedClass()
        let returnArgument = try XCTUnwrap(ReturnArgument.create())
        let roundtripped = try XCTUnwrap(returnArgument.object(obj))
        // We shouldn't get a WinRTImport wrapper back, but rather the original object
        XCTAssertIdentical(roundtripped, obj)
    }

    func testImplementsIAgileObject() throws {
        let _ = try ExportedClass().queryInterface(IAgileObjectBinding.self)
    }

    func testWeakReference() throws {
        class Exported: WinRTPrimaryExport<IInspectableBinding> {}

        var instance: Exported? = Exported()
        let weakReferencer = try WeakReferencer(XCTUnwrap(instance))
        XCTAssertNotNil(try NullResult.catch(weakReferencer.target))

        instance = withExtendedLifetime(instance) { nil }
        XCTAssertNil(try NullResult.catch(weakReferencer.target))
    }
}