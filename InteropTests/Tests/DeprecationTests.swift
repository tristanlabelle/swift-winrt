import XCTest
import WinRTComponent

class DeprecationTests: XCTestCase {
    @available(*, deprecated, message: "Deprecated to allow using deprecated symbols without warnings.")
    func testDeprecatedTypesExist() throws {
        // We can't validate that they produce deprecated messages at compile-time,
        // but we can at least validate that the types have been generated.
        _ = WinRTComponent_DeprecatedEnum.one
        _ = WinRTComponent_DeprecatedStruct().field
        _ = {} as WinRTComponent_DeprecatedDelegate
        _ = try (nil as WinRTComponent_IDeprecatedInterface?)?.property
        try (nil as WinRTComponent_IDeprecatedInterface?)?.method()
        try (nil as WinRTComponent_IDeprecatedInterface?)?.event {}
        try WinRTComponent_DeprecatedClass(42).method()
    }
}
