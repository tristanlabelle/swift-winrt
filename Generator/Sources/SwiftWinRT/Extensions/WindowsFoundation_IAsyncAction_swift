import COM
import WindowsRuntime

extension WindowsFoundation_IAsyncActionProtocol {
    public func get() async throws {
        if try self.status == .started {
            // We can't await if the completed handler is already set
            guard try COM.NullResult.catch(self.completed) == nil else { throw COM.COMError.illegalMethodCall }
            let awaiter = WindowsRuntime.AsyncAwaiter()
            try self.completed { _, _ in _Concurrency.Task { await awaiter.signal() } }
            await awaiter.wait()
        }

        return try getResults()
    }
}