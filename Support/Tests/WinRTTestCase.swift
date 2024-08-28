import XCTest
import WindowsRuntime

internal class WinRTTestCase: XCTestCase {
    private static var winRTInitialization: Result<WinRTInitialization, any Error>! = nil

    override class func setUp() {
        if winRTInitialization == nil {
            winRTInitialization = Result { try WinRTInitialization(multithreaded: false) }
        }
    }

    override func setUpWithError() throws {
        _ = try XCTUnwrap(Self.winRTInitialization).get()
        try super.setUpWithError()
    }
}