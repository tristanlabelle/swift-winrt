import XCTest
import WindowsRuntime
import WinRTComponent

class WeakReferenceTests: WinRTTestCase {
    func testNulledWhenUnreferencedFromSwift() throws {
        var target: MinimalClass! = try MinimalClass()
        let weakReference = try WeakReference<MinimalClassProjection>(target)
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        XCTAssertNil(try weakReference.resolve())
    }

    func testNulledWhenUnreferencedFromWinRT() throws {
        var target: MinimalClass! = try MinimalClass()
        let strongReferencer = try StrongReferencer(target)
        let weakReference = try WeakReference<MinimalClassProjection>(target)
        target = nil

        XCTAssertNotNil(try strongReferencer._target())
        XCTAssertNotNil(try weakReference.resolve())

        try strongReferencer.clear()

        XCTAssertNil(try NullResult.catch(strongReferencer._target()))
        XCTAssertNil(try weakReference.resolve())
    }

    func testThroughIWeakReferenceSource() throws {
        var target: MinimalClass! = try MinimalClass()
        var weakReferenceSource: IWeakReferenceSource! = try target.queryInterface(IWeakReferenceSourceProjection.self)
        let weakReference = try weakReferenceSource.getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        weakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())
    }
}