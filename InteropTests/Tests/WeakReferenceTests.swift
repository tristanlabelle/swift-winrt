import XCTest
import WindowsRuntime
import WinRTComponent

class WeakReferenceTests: WinRTTestCase {
    func testNulledWhenUnreferencedFromSwift() throws {
        var target: MinimalClass! = try MinimalClass()
        let weakReference = try WeakReference<MinimalClassBinding>(target)
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        XCTAssertNil(try weakReference.resolve())
    }

    func testNulledWhenUnreferencedFromWinRT() throws {
        var target: MinimalClass! = try MinimalClass()
        let strongReferencer = try ObjectReferencer(target)
        let weakReference = try WeakReference<MinimalClassBinding>(target)
        target = nil

        XCTAssertNotNil(try NullResult.catch(strongReferencer.target))
        XCTAssertNotNil(try weakReference.resolve())

        try strongReferencer.clear()

        XCTAssertNil(try NullResult.catch(strongReferencer.target))
        XCTAssertNil(try weakReference.resolve())
    }

    func testThroughIWeakReferenceSource() throws {
        var target: MinimalClass! = try MinimalClass()
        var weakReferenceSource: IWeakReferenceSource! = try target.queryInterface(IWeakReferenceSourceBinding.self)
        let weakReference = try weakReferenceSource.getWeakReference()
        XCTAssertNotNil(try weakReference.resolve())
        target = nil
        weakReferenceSource = nil
        XCTAssertNil(try weakReference.resolve())
    }
}