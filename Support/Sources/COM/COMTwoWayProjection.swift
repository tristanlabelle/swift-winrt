import CWinRTCore

/// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var virtualTablePointer: COMVirtualTablePointer { get }
}

/// Helpers for implementing virtual tables
extension COMTwoWayProjection {
    public static func _getImplementation(_ pointer: COMPointer) -> SwiftObject {
        COMExportBase.getImplementationUnsafe(pointer, projection: Self.self)
    }

    public static func _getImplementation(_ pointer: COMPointer?) -> SwiftObject? {
        guard let pointer else { return nil }
        return Optional(_getImplementation(pointer))
    }

    public static func _implement(_ this: COMPointer?, _ body: (SwiftObject) throws -> Void) -> CWinRTCore.SWRT_HResult {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }
        return HResult.catchValue { try body(_getImplementation(this)) }
    }

    public static func _getter<Value>(
            _ this: COMPointer?,
            _ value: UnsafeMutablePointer<Value>?,
            _ code: (SwiftObject) throws -> Value) -> CWinRTCore.SWRT_HResult {
        _implement(this) {
            guard let value else { throw HResult.Error.pointer }
            value.pointee = try code($0)
        }
    }
}
