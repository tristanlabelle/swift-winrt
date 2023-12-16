import XCTest
import WindowsRuntime
import WinRTComponent

class ReferenceCountingTests: WinRTTestCase {
    class ExportedClass: WinRTExport<IMinimalInterfaceProjection>, IMinimalInterfaceProtocol {
        public func method() throws {}
    }

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
        try XCTUnwrap(weakObj).method()

        let referencer = try ObjectReferencer()
        try referencer.begin(obj)
        try XCTUnwrap(weakObj).method()

        obj = nil // We should now only be kept alive by WinRT
        try XCTUnwrap(weakObj).method()

        let _ = try referencer.end() // Resulting refcount is unreliable as it includes weak ref counts
        XCTAssertNil(weakObj)
    }
}