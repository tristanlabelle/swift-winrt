public struct SwiftAttribute: ExpressibleByStringLiteral {
    public var literal: String
    public init(_ literal: String) { self.literal = literal }
    public init(stringLiteral literal: String) { self.literal = literal }

    public static var discardableResult: SwiftAttribute { "discardableResult" }
}