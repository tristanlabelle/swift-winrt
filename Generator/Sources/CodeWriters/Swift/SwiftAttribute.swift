public struct SwiftAttribute {
    public var literal: String
    public init(_ literal: String) { self.literal = literal }

    public static var discardableResult: SwiftAttribute { .init("discardableResult") }
    public static var mainActor: SwiftAttribute { .init("mainActor") }
}