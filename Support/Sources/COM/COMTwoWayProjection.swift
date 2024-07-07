import WindowsRuntime_ABI

/// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var virtualTablePointer: UnsafeRawPointer { get }
}

extension COMTwoWayProjection {
    public static func _unwrap(_ pointer: ABIPointer) -> SwiftObject? {
        COMEmbedding.getImplementation(pointer)
    }

    /// Helper for implementing virtual tables
    public static func _implement(_ this: ABIPointer?, _ body: (SwiftObject) throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return HResult.catchValue { try body(implementation) }
    }

    public static func _set<Value>(
            _ pointer: UnsafeMutablePointer<Value>?,
            _ value: @autoclosure () throws -> Value) throws {
        guard let pointer else { throw HResult.Error.pointer }
        pointer.pointee = try value()
    }
}
