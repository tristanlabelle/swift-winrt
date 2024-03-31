/// Represents x- and y-coordinate values that define a point in a two-dimensional plane.
public struct WindowsFoundation_Point: Hashable, Codable {
    /// The horizontal position of the point.
    public var x: Swift.Float

    /// The vertical position of the point.
    public var y: Swift.Float

    public init() {
        self.x = 0
        self.y = 0
    }

    public init(x: Swift.Float, y: Swift.Float) {
        self.x = x
        self.y = y
    }
}