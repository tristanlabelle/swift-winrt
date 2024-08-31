/// Error thrown when a COM or WinRT projection returns a null pointer.
///
/// - Remarks:
/// The WinRT type system implies that all values of reference types can be `null`,
/// although in practice APIs will seldom return `null` values with successful `HRESULT`.
///
/// If returned reference types are exposed as `Optional<T>` in Swift,
/// it forces consumers of APIs to handle errors in two ways:
/// 1. With the `try` keyword for errors thrown due to failure HRESULTs.
/// 2. With Optional-unwrapping logic for `null` values.
/// Moreover, it means that code needs to explicitly unwrap the `Optional<T>` even
/// for APIs known to not return `null`, adding boilerplate and confusion as to
/// whether a real possible error is being handled or not.
///
/// `NullResult` allows the projection to generate non-nullable return types
/// while turning `null` return values into Swift errors thrown and handled the same way as HRESULTs.
/// It is transparent in the typical case of APIs not returning `null`, but incurs
/// additional syntax when `null` values must be handled.
///
/// The other alternative would be generate return types as implicitly unwrapped optionals,
/// which allows comparisons to `nil` and chaining with `.`, but have the disadvantage
/// of introducing implicit `fatalError`'s, of decaying into a standard optional when stored,
/// and of still requiring different failure handling as HRESULTs.
public struct NullResult: Error {
    /// Unwraps a nullable value, throwing a `NullResult` if it is null.
    public static func unwrap<Value>(_ value: Value?) throws -> Value {
        guard let value else { throw NullResult() }
        return value
    }

    /// Converts any thrown `NullResult` error into a null value Optional.
    public static func `catch`<Value>(_ block: @autoclosure () throws -> Value) rethrows -> Value? {
        do { return try block() }
        catch is NullResult { return nil }
        catch { throw error }
    }
}