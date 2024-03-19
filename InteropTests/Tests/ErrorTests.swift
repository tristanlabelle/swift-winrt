import XCTest
import COM
import WindowsRuntime
import WinRTComponent

class ErrorTests: WinRTTestCase {
    func testCatchErrorHResult() throws {
        let hresult = HResult(unsigned: 0xBAADF00D)
        do {
            try Errors.failWith(hresult, "")
            XCTFail("Expected an error")
        } catch let error as COMError {
            XCTAssertEqual(error.hresult, hresult)
        }
    }

    func testCatchErrorMessage() throws {
        let hresult = HResult(unsigned: 0xDEADBEEF)
        let message = "Hit some beef"
        do {
            try Errors.failWith(hresult, message)
            XCTFail("Expected an error")
        } catch let error as WinRTError {
            XCTAssertEqual(error.description, message)
        }
    }

    func testCallThrowingProperty() throws {
        XCTAssertThrowsError(try Errors._notImplementedProperty())
        XCTAssertThrowsError(try Errors._notImplementedProperty("foo"))
    }

    func testThrowWithHResult() throws {
        let hresult = HResult(unsigned: 0xCAFEBABE)
        let error = try XCTUnwrap(HResult.Error(hresult: hresult))
        XCTAssertEqual(
            try Errors.catchHResult { throw error },
            hresult)
    }

    func testThrowWithMessage() throws {
        throw XCTSkip("Not implemented: RoOriginateError")
    }
}