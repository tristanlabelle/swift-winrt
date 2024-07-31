/// Represents a registration of an event handler with an event source and supports removing the registration.
public struct EventRegistration {
    // We store and pass in the event source object so removal closures do not need to capture context, avoiding allocations.
    public typealias Remover = (_ source: AnyObject, _ token: EventRegistrationToken) throws -> Void

    /// The object that is the source of the event.
    private var source: AnyObject
    /// The token that represents the event registration.
    public private(set) var token: EventRegistrationToken
    /// The closure that removes the event registration.
    private var remover: Remover

    public init(source: AnyObject, token: EventRegistrationToken, remover: @escaping Remover) {
        self.source = source
        self.token = token
        self.remover = remover
    }

    public mutating func detachToken() -> EventRegistrationToken {
        remover = Self.nullRemover
        defer { token = .none }
        return token
    }

    public mutating func remove() throws {
        try remover(source, token)
        token = .none
        remover = Self.nullRemover
    }

    private static let nullRemover: Remover = { _, _ in }
}