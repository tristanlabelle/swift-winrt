import XCTest
import WindowsRuntime
import WinRTComponent

class ObjectExportingTests: WinRTTestCase {
    class ExportedClass: WinRTExport<IInspectableProjection> {}

    func testBalancedAddRefRelease() throws {
        let obj: ExportedClass = .init()
        let referencer = try ObjectReferencer()
        try referencer.begin(obj)
        let postAddRefCount = try referencer.callAddRef()
        XCTAssert(postAddRefCount > 1)
        let postReleaseRefCount = try referencer.callRelease()
        XCTAssert(postReleaseRefCount == postAddRefCount - 1)
    }

    func testReleaseFromWinRT() throws {
        var obj: ExportedClass? = ExportedClass()
        weak var weakObj = obj
        XCTAssertNotNil(weakObj)

        let referencer = try ObjectReferencer()
        try referencer.begin(obj)
        XCTAssertNotNil(weakObj)

        obj = nil // We should now only be kept alive by WinRT
        XCTAssertNotNil(weakObj)

        let _ = try referencer.end() // Resulting refcount is unreliable as it includes weak ref counts
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
        let _ = try ExportedClass().queryInterface(IAgileObjectProjection.self)
    }
}