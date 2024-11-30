import XCTest
import WindowsRuntime

internal class WinRTTestCase: XCTestCase {
    // Due to caching in the projections, we can't deinitialize the WinRT runtime after each test
    private static var winRTInitialization: WinRTInitialization? = nil

    override func setUpWithError() throws {
        if Self.winRTInitialization == nil {
            Self.winRTInitialization = try WinRTInitialization(multithreaded: false)
        }

        try super.setUpWithError()
    }
}