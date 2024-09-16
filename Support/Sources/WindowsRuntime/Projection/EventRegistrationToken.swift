import COM
import WindowsRuntime_ABI

public struct EventRegistrationToken: Hashable, Sendable {
    public var value: Int64
    public init(_ value: Int64 = 0) { self.value = value }

    public static let none = Self(0)
}

extension EventRegistrationToken: PODBinding {
    public typealias SwiftValue = Self
    public typealias ABIValue = WindowsRuntime_ABI.SWRT_EventRegistrationToken

    public static var abiDefaultValue: ABIValue { WindowsRuntime_ABI.SWRT_EventRegistrationToken(value: 0) }
    public static func toSwift(_ value: ABIValue) -> SwiftValue { SwiftValue(value.value) }
    public static func toABI(_ value: SwiftValue) -> ABIValue { ABIValue(value: value.value) }
}