public struct EventRegistration {
    public typealias Remover = (_ source: AnyObject, _ token: EventRegistrationToken) throws -> Void

    public private(set) var source: AnyObject
    public private(set) var token: EventRegistrationToken
    public private(set) var remover: Remover

    public init(source: AnyObject, token: EventRegistrationToken, remover: @escaping Remover) {
        self.source = source
        self.token = token
        self.remover = remover
    }

    public mutating func detachToken() -> EventRegistrationToken {
        defer { token = .none }
        remover = Self.nullRemover
        return token
    }

    public mutating func remove() throws {
        try remover(source, token)
        token = .none
        remover = Self.nullRemover
    }

    private static let nullRemover: Remover = { _, _ in }
}