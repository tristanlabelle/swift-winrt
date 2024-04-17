/// Represents number values that specify a height and width.
public struct WindowsFoundation_Size: Hashable, Codable, Sendable {
    /// The width.
    public var width: Swift.Float

    /// The height.
    public var height: Swift.Float

    public init() {
        self.width = 0
        self.height = 0
    }

    public init(width: Swift.Float, height: Swift.Float) {
        self.width = width
        self.height = height
    }
}