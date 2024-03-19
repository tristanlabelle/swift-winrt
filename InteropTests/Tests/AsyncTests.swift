import COM
import XCTest
import WinRTComponent

class AsyncTests : XCTestCase {
    public func testAwaitAlreadyCompleted() async throws {
        let asyncOperation = try ManualAsyncOperation(0)
        XCTAssertEqual(try asyncOperation._status(), .started)
        try asyncOperation.complete(42)
        XCTAssertEqual(try asyncOperation._status(), .completed)
        let result = try await asyncOperation.get()
        XCTAssertEqual(result, 42)
    }

    public func testAwaitAlreadyFailed() async throws {
        let asyncOperation = try ManualAsyncOperation(0)
        XCTAssertEqual(try asyncOperation._status(), .started)
        try asyncOperation.completeWithError(HResult.outOfMemory)
        XCTAssertEqual(try asyncOperation._status(), .error)
        do {
            let _ = try await asyncOperation.get()
            XCTFail("Expected an exception to be thrown")
        }
        catch let error as COMError {
            XCTAssertEqual(error.hresult, HResult.outOfMemory)
        }
    }

    public func testAwaitNotYetCompleted() async throws {
        let asyncOperation = try ManualAsyncOperation(0)
        XCTAssertEqual(try asyncOperation._status(), .started)
        Self.runAfter(delay: 0.05) { try? asyncOperation.complete(42) }
        let result = try await asyncOperation.get()
        XCTAssertEqual(try asyncOperation._status(), .completed)
        XCTAssertEqual(result, 42)
    }

    public func testAwaitNotYetFailed() async throws {
        let asyncOperation = try ManualAsyncOperation(0)
        XCTAssertEqual(try asyncOperation._status(), .started)
        Self.runAfter(delay: 0.05) { try? asyncOperation.completeWithError(HResult.outOfMemory) }
        do {
            let _ = try await asyncOperation.get()
            XCTFail("Expected an exception to be thrown")
        }
        catch let error as COMError {
            XCTAssertEqual(try asyncOperation._status(), .error)
            XCTAssertEqual(error.hresult, HResult.outOfMemory)
        }
    }

    public func testAwaitWithExistingCompletionHandler() async throws {
        let asyncOperation = try ManualAsyncOperation(0)
        try asyncOperation._completed { _, _ in }
        do {
            let _ = try await asyncOperation.get()
            XCTFail("Expected an exception to be thrown")
        }
        catch let error as COMError {
            XCTAssertEqual(try asyncOperation._status(), .started)
            XCTAssertEqual(error.hresult, HResult.illegalMethodCall)
        }
    }

    /// Runs a block asynchronously after a delay has elapsed
    private static func runAfter(delay: TimeInterval, body: @escaping () -> Void) {
        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            body()
        }
    }
}