public struct SwiftDocumentationComment {
    public var summary: [Block]?
    public var params = [Param]()
    public var returns: [Span]?

    public init() {}

    public enum Block: Hashable {
        case paragraph([Span])
        case code(String)
        case list([Span])

        public static func paragraph(_ span: Span) -> Block { .paragraph([span]) }
        public static func paragraph(_ text: String) -> Block { .paragraph(.text(text)) }
    }

    public enum Span: Hashable {
        case text(String)
        case code(String)
    }

    public struct Param {
        public var name: String
        public var description: [Span]

        public init(name: String, description: [Span]) {
            self.name = name
            self.description = description
        }
    }
}