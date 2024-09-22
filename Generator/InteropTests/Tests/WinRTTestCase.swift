import XCTest
import WindowsRuntime

class WinRTTestCase: XCTestCase {
    // Only created once before the first test of any test case runs,
    // and never freed because we don't know when we've run the last test,
    // and reinitializing WinRT could invalidate cached activation factories.
    private static let initialization: Result<WinRTInitialization, any Error>
        = Result { try WinRTInitialization(multithreaded: true) }

    override class func setUp() {
        // Enforce that the static initializer runs before any tests.
        _ = try? initialization.get()
    }

    override func setUpWithError() throws {
        _ = try Self.initialization.get()
    }
}