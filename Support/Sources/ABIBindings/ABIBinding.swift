/// Describes how to bind an ABI type to a Swift type,
/// including how to convert values between the two representations.
public protocol ABIBinding {
    // The type for the ABI representation of values.
    associatedtype ABIValue

    /// The type for the Swift representation of values.
    associatedtype SwiftValue

    /// A default ABI value that can be used to initialize variables
    /// and does not imply any resource allocation (release is a no-op).
    static var abiDefaultValue: ABIValue { get }

    /// Converts a value from its ABI to its Swift representation
    /// without releasing the original value.
    static func fromABI(_ value: ABIValue) -> SwiftValue

    /// Converts a value from its ABI to its Swift representation,
    /// releasing the original value.
    static func fromABI(consuming value: inout ABIValue) -> SwiftValue

    /// Converts a value from its Swift to its ABI representation.
    /// The resulting value should be released as its creation might have allocated resources.
    static func toABI(_ value: SwiftValue) throws -> ABIValue

    /// Releases up any allocated resources associated with the ABI representation of a value.
    static func release(_ value: inout ABIValue)
}

extension ABIBinding {
    public static func fromABI(consuming value: inout ABIValue) -> SwiftValue {
        defer { release(&value) }
        return fromABI(value)
    }

    public static func withABI<Result>(_ value: SwiftValue, _ closure: (ABIValue) throws -> Result) throws -> Result {
        var abiValue = try toABI(value)
        defer { release(&abiValue) }
        return try closure(abiValue)
    }
}

public enum ABIBindingError: Error {
    case unsupported(Any.Type)
}