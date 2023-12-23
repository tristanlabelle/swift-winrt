public actor AsyncAwaiter {
    private enum State {
        case unsignaled
        case awaitingSignal(continuation: CheckedContinuation<Void, Never>)
        case signaled
    }

    private var state: State = .unsignaled

    public init() {}

    /// Block until the signal() has been called.
    public func wait() async {
        switch state {
            case .signaled: return
            case .awaitingSignal: fatalError("Reentrant wait() call")
            case .unsignaled:
                await withCheckedContinuation { state = .awaitingSignal(continuation: $0) }
        }
    }

    /// Unblocks any current or future wait() calls.
    public func signal() async {
        switch state {
            case .unsignaled: state = .signaled
            case .awaitingSignal(let continuation):
                state = .signaled
                continuation.resume()
            case .signaled: break
        }
    }
}