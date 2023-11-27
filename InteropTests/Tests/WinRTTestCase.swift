import XCTest
import WindowsRuntime

class WinRTTestCase: XCTestCase {
    internal class var singleThreadedApartment: Bool { false }

    private static var initialization: Result<WinRTInitialization, Error>?

    override class func setUp() {
        initialization = Result { try WinRTInitialization(multithreaded: !singleThreadedApartment) }
    }

    override func setUpWithError() throws {
        _ = try Self.initialization?.get()
    }

    override class func tearDown() {
        initialization = nil
    }
}