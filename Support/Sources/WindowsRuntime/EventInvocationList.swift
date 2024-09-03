/// Manages a list of handler delegates for an event.
public struct EventInvocationList<Delegate>: ~Copyable {
    private var implementation: Implementation? = nil

    public init() {}

    public mutating func add(_ handler: Delegate?) throws -> EventRegistration {
        guard let handler else { throw COMError.pointer }
        if implementation == nil { implementation = Implementation() }
        return try implementation!.add(handler)
    }

    public mutating func remove(_ token: WindowsRuntime.EventRegistrationToken) throws {
        guard let implementation else { throw COMError.invalidArg }
        try implementation.remove(token)
    }

    public func invoke(_ invoker: (Delegate) throws -> Void) rethrows {
        try implementation?.invoke(invoker)
    }

    private class Implementation {
        private var handlers = [(Delegate, token: EventRegistrationToken)]()
        private var nextTokenValue: Int64 = 1

        public func add(_ handler: Delegate) throws -> EventRegistration {
            let token = EventRegistrationToken(nextTokenValue)
            handlers.append((handler, token: token))
            nextTokenValue += 1
            return EventRegistration(source: self, token: token, remover: Self.remove)
        }

        public func remove(_ token: WindowsRuntime.EventRegistrationToken) throws {
            guard let index = handlers.firstIndex(where: { $0.token == token }) else { throw COMError.invalidArg }
            handlers.remove(at: index)
        }

        private static func remove(_ source: AnyObject, _ token: EventRegistrationToken) throws {
            try (source as! Implementation).remove(token)
        }

        public func invoke(_ invoker: (Delegate) throws -> Void) rethrows {
            for (handler, _) in handlers { try invoker(handler) }
        }
    }
}