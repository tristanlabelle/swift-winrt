import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class ErrorTests: WinRTTestCase {
    func testCatchErrorHResult() throws {
        let hresult = HResult(unsigned: 0xBAADF00D)
        do {
            try WinRTComponent_Errors.failWith(hresult, "")
            XCTFail("Expected an error")
        } catch let error as COMErrorProtocol {
            XCTAssertEqual(error.hresult, hresult)
        }
    }

    func testCatchErrorMessage() throws {
        let hresult = HResult(unsigned: 0xDEADBEEF)
        let message = "Hit some beef"
        do {
            try WinRTComponent_Errors.failWith(hresult, message)
            XCTFail("Expected an error")
        } catch let error as WinRTError {
            XCTAssertEqual(error.description, message)
        }
    }

    func testCallThrowingProperty() throws {
        XCTAssertThrowsError(try WinRTComponent_Errors.notImplementedProperty)
        XCTAssertThrowsError(try WinRTComponent_Errors.notImplementedProperty("foo"))
    }

    func testThrowWithHResult() throws {
        struct TestError: ErrorWithHResult {
            public var hresult: HResult { .init(unsigned: 0xCAFEBABE) }
        }
        let error = TestError()
        XCTAssertEqual(try WinRTComponent_Errors.catchHResult { throw error }, error.hresult)
    }

    func testThrowWithMessage() throws {
        struct TestError: Error, CustomStringConvertible {
            public var description: String { "test" }
        }
        let error = TestError()
        XCTAssertEqual(try WinRTComponent_Errors.catchMessage { throw error }, error.description)
    }

    func testSwiftErrorPreserved() throws {
        struct SwiftError: Error {}
        do {
            try WinRTComponent_Errors.call { throw SwiftError() }
            XCTFail("Expected an error")
        }
        catch _ as SwiftError {} // Success
    }
}