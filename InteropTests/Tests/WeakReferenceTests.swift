import XCTest
import WindowsRuntime
import WinRTComponent

class WeakReferenceTests: WinRTTestCase {
    func testNulledWhenUnreferencedFromSwift() throws {
        var target: WinRTComponent_MinimalClass! = try WinRTComponent_MinimalClass()
        let weakReference = try WeakReference<WinRTComponent_MinimalClassBinding>(target)
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        XCTAssertNil(try weakReference.resolve())
    }

    func testNulledWhenUnreferencedFromWinRT() throws {
        var target: WinRTComponent_MinimalClass! = try WinRTComponent_MinimalClass()
        let strongReferencer = try WinRTComponent_ObjectReferencer(target)
        let weakReference = try WeakReference<WinRTComponent_MinimalClassBinding>(target)
        target = nil

        XCTAssertNotNil(try NullResult.catch(strongReferencer.target))
        XCTAssertNotNil(try weakReference.resolve())

        try strongReferencer.clear()

        XCTAssertNil(try NullResult.catch(strongReferencer.target))
        XCTAssertNil(try weakReference.resolve())
    }

    func testThroughIWeakReferenceSource() throws {
        var target: WinRTComponent_MinimalClass! = try WinRTComponent_MinimalClass()
        var weakReferenceSource: WinRTComponent_IWeakReferenceSource! = try target.queryInterface(WinRTComponent_IWeakReferenceSourceBinding.self)
        let weakReference = try weakReferenceSource.getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        weakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())
    }
}