/// A wrapper around an unowned reference to an object.
internal struct Unowned<Object>: Hashable where Object: AnyObject {
    unowned var object: Object

    public init(_ object: Object) {
        self.object = object
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(object))
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.object === rhs.object
    }
}