import WindowsRuntime_ABI

/// Protocol for strongly-typed two-way COM interface projections into and from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var virtualTablePointer: UnsafeRawPointer { get }
}

extension COMTwoWayProjection {
    public static func toCOM(_ object: SwiftObject) throws -> COMReference<COMInterface> {
        if let unknown = object as? IUnknown {
            // The object manages its com representation directly.
            return try unknown._queryInterface(Self.self)
        } else {
            // Create a wrapper to manage the COM representation.
            return COMWrappingExport<Self>(implementation: object).toCOM()
        }
    }

    public static func _unwrap(_ pointer: COMPointer) -> SwiftObject? {
        COMEmbedding.getImplementation(pointer)
    }

    /// Helper for implementing virtual tables
    public static func _implement(_ this: COMPointer?, _ body: (SwiftObject) throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
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
