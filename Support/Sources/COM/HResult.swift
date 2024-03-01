import WindowsRuntime_ABI

public struct HResult: Hashable, CustomStringConvertible {
    public typealias Value = Int32
    public typealias UnsignedValue = UInt32

    public static let ok = HResult(0)
    public static let illegalMethodCall = HResult(unsigned: 0x8000000E)
    public static let fail = HResult(unsigned: 0x80004005)
    public static let invalidArg = HResult(unsigned: 0x80070057)
    public static let notImpl = HResult(unsigned: 0x80004001)
    public static let noInterface = HResult(unsigned: 0x80004002)
    public static let pointer = HResult(unsigned: 0x80004003)
    public static let outOfMemory = HResult(unsigned: 0x8007000E)

    public var value: Value
    public var unsignedValue: UnsignedValue { UnsignedValue(bitPattern: value) }

    public init(_ value: Value) { self.value = value }
    public init(unsigned: UnsignedValue) { self.value = Value(bitPattern: unsigned) }

    public var isSuccess: Bool { Self.isSuccess(value) }
    public var isFailure: Bool { Self.isFailure(value) }

    public var message: String? { Self.getMessage(value) }

    public var hexValue: String {
        let prepaddedValue = UInt64(unsignedValue) | (UInt64(0xFF) << 32)
        var result = String(prepaddedValue, radix: 16, uppercase: true)
        result.replaceSubrange(result.firstRange(of: "FF")!, with: "0x")
        return result
    }

    public var description: String {
        if let message = self.message {
            return "HRESULT(\(hexValue)): \(message)"
        }

        return "HRESULT(\(hexValue))"
    }

    public static func isSuccess(_ hr: Value) -> Bool { hr >= 0 }
    public static func isFailure(_ hr: Value) -> Bool { hr < 0 }
}