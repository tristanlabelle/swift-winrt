/// Contains number values that represent the location and size of a rectangle.
public struct WindowsFoundation_Rect: Hashable, Codable, Sendable {
    /// The x-coordinate of the upper-left corner of the rectangle.
    public var x: Swift.Float

    /// The y-coordinate of the upper-left corner of the rectangle.
    public var y: Swift.Float

    /// The width of the rectangle, in pixels.
    public var width: Swift.Float

    /// The height of the rectangle, in pixels.
    public var height: Swift.Float

    public init() {
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
    }

    public init(x: Swift.Float, y: Swift.Float, width: Swift.Float, height: Swift.Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}