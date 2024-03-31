/// Represents an instant in time, typically expressed as a date and time of day.
public struct WindowsFoundation_DateTime: Hashable, Codable {
    /// A 64-bit signed integer that represents a point in time as the number of 100-nanosecond intervals prior to or after midnight on January 1, 1601 (according to the Gregorian Calendar).
    public var universalTime: Swift.Int64

    public init() {
        self.universalTime = 0
    }

    public init(universalTime: Swift.Int64) {
        self.universalTime = universalTime
    }
}

import struct Foundation.Date

extension WindowsFoundation_DateTime {
    public init(foundationDate: Foundation.Date) {
        self.init(universalTime: (Int64(foundationDate.timeIntervalSince1970 * 1000) + 11_644_473_600_000) * 10_000)
    }

    public var foundationDate: Foundation.Date {
        get {
            Date(timeIntervalSince1970: Double(universalTime / 10_000) / 1000 - 11_644_473_600)
        }
        set {
            self = Self(foundationDate: newValue)
        }
    }
}