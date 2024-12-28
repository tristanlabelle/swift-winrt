import XCTest
import WinRTComponent

class DeprecationTests: XCTestCase {
    @available(*, deprecated, message: "Deprecated to allow using deprecated symbols without warnings.")
    func testDeprecatedTypesExist() {
        // We can't validate that they produce deprecated messages at compile-time,
        // but we can at least validate that the types have been generated.
        _ = DeprecatedEnum.one
        _ = DeprecatedStruct().Field
        _ = {} as DeprecatedDelegate
        _ = try (nil as IDeprecatedInterface?)?.property
        try (nil as IDeprecatedInterface?)?.method()
        try (nil as IDeprecatedInterface?)?.event {}
        DeprecatedClass(42).method()
    }
}
