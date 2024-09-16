/// Represents a time interval as a signed 64-bit integer value.
public struct WindowsFoundation_TimeSpan: Hashable, Codable, Sendable {
    /// A time period expressed in 100-nanosecond units.
    public var duration: Swift.Int64

    public init() {
        self.duration = 0
    }

    public init(duration: Swift.Int64) {
        self.duration = duration
    }
}

// Conversion to and from Swift.Duration
extension WindowsFoundation_TimeSpan {
    private static let secondsPerNanosecond = 1_000_000_000 // 10^−9 seconds
    private static let nanosecondsPerTick = 100 // 10^−7 seconds
    private static let ticksPerSecond = secondsPerNanosecond / nanosecondsPerTick
    private static let attosecondsPerNanosecond = 1_000_000_000
    private static let attosecondsPerTick = Int64(attosecondsPerNanosecond) * Int64(nanosecondsPerTick)

    public init(duration: Swift.Duration) {
        self.duration = duration.components.seconds * Int64(Self.ticksPerSecond)
            + duration.components.attoseconds / Self.attosecondsPerTick
    }

    public var swiftDuration: Swift.Duration {
        .nanoseconds(duration * Int64(Self.nanosecondsPerTick))
    }
}

// Conversion to and from Foundation.TimeInterval
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

// Binding
import SWRT_WindowsFoundation

extension WindowsFoundation_TimeSpan: StructBinding, PODBinding {
    public typealias SwiftValue = WindowsFoundation_TimeSpan
    public typealias ABIValue = SWRT_WindowsFoundation_TimeSpan

    public static var typeName: String { "Windows.Foundation.TimeSpan" }
    public static var ireferenceID: COMInterfaceID { 
        COMInterfaceID(0x604D0C4C, 0x91DE, 0x5C2A, 0x935F, 0x362F13EAF800)
    }

    public static var ireferenceArrayID: COM.COMInterfaceID {
        COMInterfaceID(0xAD73197D, 0x2CFA, 0x57A6, 0x8993, 0x9FAC40FEB791)
    }

    public static var abiDefaultValue: ABIValue { .init() }

    public static func fromABI(_ value: ABIValue) -> SwiftValue {
        .init(duration: value.Duration)
    }

    public static func toABI(_ value: SwiftValue) -> ABIValue {
        .init(Duration: value.duration)
    }

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        try PropertyValueStatics.createIReference(value, valueBinding: Self.self, factory: PropertyValueStatics.createTimeSpan)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        try PropertyValueStatics.createIReferenceArray(value, valueBinding: Self.self, factory: PropertyValueStatics.createTimeSpanArray)
    }
}