import XCTest
import WindowsRuntime

class WinRTTestCase: XCTestCase {
    // Only created once before the first test of any test case runs,
    // and never freed because we don't know when we've run the last test,
    // and reinitializing WinRT could invalidated cached activation factories.
    private static var initialization: Result<WinRTInitialization, any Error>
        = Result { try WinRTInitialization(multithreaded: true) }

    override func setUpWithError() throws {
        _ = try Self.initialization.get()
    }
}