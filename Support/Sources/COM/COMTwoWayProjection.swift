import WindowsRuntime_ABI

/// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var virtualTablePointer: COMVirtualTablePointer { get }
}

/// Helpers for implementing virtual tables
extension COMTwoWayProjection {
    public static func _implement(_ this: COMPointer?, _ body: (SwiftObject) throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        let implementation: SwiftObject = COMExportBase.getImplementationUnsafe(this)
        return HResult.catchValue { try body(implementation) }
    }

    public static func _set<Value>(
            _ pointer: UnsafeMutablePointer<Value>?,
            _ value: @autoclosure () throws -> Value) throws {
        guard let pointer else { throw HResult.Error.pointer }
        pointer.pointee = try value()
    }
}
