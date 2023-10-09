public enum OptionalProjection<Inner: ABIProjection>: ABIProjection {
    public typealias SwiftValue = Inner.SwiftValue?
    public typealias ABIValue = Inner.ABIValue?

    public static func toSwift(copying value: Inner.ABIValue?) -> Inner.SwiftValue? {
        guard let value else { return nil }
        return Inner.toSwift(copying: value)
    }

    public static func toSwift(consuming value: Inner.ABIValue?) -> Inner.SwiftValue? {
        guard let value else { return nil }
        return Inner.toSwift(consuming: value)
    }

    public static func toABI(_ value: Inner.SwiftValue?) throws -> Inner.ABIValue? {
        guard let value else { return nil }
        return try Inner.toABI(value)
    }

    public static func release(_ value: Inner.ABIValue?) {
        if let value { Inner.release(value) }
    }
}
