// We don't project Windows.Foundation.DataTime to Foundation.Date because
// the latter can only be constructed from a Foundation.TimeInterval,
// which is a floating-point number and would lose precision vs DataTime.

/// Represents an instant in time, typically expressed as a date and time of day.
public struct WindowsFoundation_DateTime: Hashable, Codable, Sendable {
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

import SWRT_WindowsFoundation

extension WindowsFoundation_DateTime: WindowsRuntime.StructBinding, COM.PODBinding {
    public typealias SwiftValue = Self
    public typealias ABIValue = SWRT_WindowsFoundation_DateTime

    public static let typeName = "Windows.Foundation.DateTime"

    public static var ireferenceID: COM.COMInterfaceID {
        COMInterfaceID(0x5541D8A7, 0x497C, 0x5AA4, 0x86FC, 0x7713ADBF2A2C)
    }

    public static var ireferenceArrayID: COM.COMInterfaceID {
        COMInterfaceID(0x1B8E9594, 0x588E, 0x5A07, 0x9E65, 0x0731A4C9A2DB)
    }

    public static var abiDefaultValue: ABIValue { .init() }

    public static func toSwift(_ value: ABIValue) -> SwiftValue {
        .init(universalTime: value.UniversalTime)
    }

    public static func toABI(_ value: SwiftValue) -> ABIValue {
        .init(UniversalTime: value.universalTime)
    }

    public static func createIReference(_ value: SwiftValue) throws -> WindowsFoundation_IReference<SwiftValue> {
        try PropertyValueStatics.createIReference(value, valueBinding: Self.self, factory: PropertyValueStatics.createDateTime)
    }

    public static func createIReferenceArray(_ value: [SwiftValue]) throws -> WindowsFoundation_IReferenceArray<SwiftValue> {
        try PropertyValueStatics.createIReferenceArray(value, valueBinding: Self.self, factory: PropertyValueStatics.createDateTimeArray)
    }
}