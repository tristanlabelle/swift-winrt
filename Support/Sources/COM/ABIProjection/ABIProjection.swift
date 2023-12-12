/// A type that manages the projection between the Swift and ABI representation of a type of values.
public protocol ABIProjection {
    /// The type for the Swift representation of values.
    associatedtype SwiftValue

    // The type for the ABI representation of values.
    associatedtype ABIValue

    /// A default ABI value that can be used to initialize variables
    /// and does not imply any resource allocation (release is a no-op).
    static var abiDefaultValue: ABIValue { get }

    /// Converts a value from its ABI to its Swift representation
    /// without releasing the original value.
    static func toSwift(_ value: ABIValue) -> SwiftValue

    /// Converts a value from its ABI to its Swift representation,
    /// releasing the original value.
    static func toSwift(consuming value: inout ABIValue) -> SwiftValue

    /// Converts a value from its Swift to its ABI representation.
    /// The resulting value should be released as its creation might have allocated resources.
    static func toABI(_ value: SwiftValue) throws -> ABIValue

    /// Releases up any allocated resources associated with the ABI representation of a value.
    static func release(_ value: inout ABIValue)
}

extension ABIProjection {
    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue {
        defer { release(&value) }
        return toSwift(value)
    }

    public static func withABI<Result>(_ value: SwiftValue, _ closure: (ABIValue) throws -> Result) throws -> Result {
        var abiValue = try toABI(value)
        defer { release(&abiValue) }
        return try closure(abiValue)
    }
}

/// A type that projects values between Swift and ABI representations,
/// where the ABI representation requires no resource allocation.
/// For conformance convenience.
public protocol ABIInertProjection: ABIProjection {
    static func toABI(_ value: SwiftValue) -> ABIValue // No throw version
}

extension ABIInertProjection {
    public static func toSwift(consuming value: inout ABIValue) -> SwiftValue { toSwift(value) }
    public static func release(_ value: inout ABIValue) {}
}

public protocol ABIIdentityProjection: ABIInertProjection where SwiftValue == ABIValue {}

extension ABIIdentityProjection {
    public static func toABI(_ value: SwiftValue) -> ABIValue { value }
    public static func toSwift(_ value: ABIValue) -> SwiftValue { value }
}

public enum ABIProjectionError: Error {
    case unsupported(Any.Type)
}