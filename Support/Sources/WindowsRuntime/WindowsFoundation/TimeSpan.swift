/// Represents a time interval as a signed 64-bit integer value.
public struct WindowsFoundation_TimeSpan: Hashable, Codable {
    /// A time period expressed in 100-nanosecond units.
    public var duration: Swift.Int64

    public init() {
        self.duration = 0
    }

    public init(duration: Swift.Int64) {
        self.duration = duration
    }
}

import struct Foundation.TimeInterval

extension WindowsFoundation_TimeSpan {
    public init(timeInterval: Foundation.TimeInterval) {
        self.init(duration: Int64(timeInterval * 10_000_000))
    }

    public var timeInterval: Foundation.TimeInterval {
        get {
            Double(duration) / 10_000_000
        }
        set {
            self = Self(timeInterval: newValue)
        }
    }
}