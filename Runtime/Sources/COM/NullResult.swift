// Error thrown when a COM or WinRT projection returns a null pointer.
public struct NullResult: Error {
    public static func unwrap<Value>(_ value: Value?) throws -> Value {
        guard let value else { throw NullResult() }
        return value
    }

    public static func `catch`<Value>(_ block: () throws -> Value) rethrows -> Value? {
        do { return try block() }
        catch is NullResult { return nil }
        catch { throw error }
    }
}