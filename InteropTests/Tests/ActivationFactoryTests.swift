import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class ActivationFactoryTests: WinRTTestCase {
    func testDefault() throws {
        XCTAssertEqual(try WinRTComponent_OverloadedSum().result, 0)
    }

    func testParameterized() throws {
        XCTAssertEqual(try WinRTComponent_OverloadedSum(1).result, 1)
        XCTAssertEqual(try WinRTComponent_OverloadedSum(1, 2).result, 3)
    }
}