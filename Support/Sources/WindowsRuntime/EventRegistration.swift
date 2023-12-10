public struct EventRegistration {
    public typealias Remover = (_ removing: EventRegistrationToken) throws -> Void

    public private(set) var token: EventRegistrationToken
    public private(set) var remover: Remover

    public init(token: EventRegistrationToken, remover: @escaping Remover) {
        self.token = token
        self.remover = remover
    }

    public mutating func detachToken() -> EventRegistrationToken {
        defer { token = .none }
        remover = Self.nullRemover
        return token
    }

    public mutating func remove() throws {
        try remover(token)
        token = .none
        remover = Self.nullRemover
    }

    private static let nullRemover: Remover = { _ in }
}