import COM_ABI

/// Protocol for COM interfaces projected into Swift both for consuming COM objects
/// and for implementing the interface from Swift.
public protocol COMTwoWayProjection: COMProjection {
    static var virtualTablePointer: UnsafeRawPointer { get }
}

extension COMTwoWayProjection {
    public static func _unwrap(_ pointer: ABIPointer) -> SwiftObject? {
        COMEmbedding.getImplementation(pointer)
    }

    /// Helper for implementing virtual tables
    public static func _implement<This>(_ this: UnsafeMutablePointer<This>?, _ body: (SwiftObject) throws -> Void) -> COM_ABI.SWRT_HResult {
        guard let this else { return COMError.toABI(hresult: HResult.pointer, description: "COM 'this' pointer was null") }
        let implementation: SwiftObject = COMEmbedding.getImplementationOrCrash(this)
        return COMError.toABI { try body(implementation) }
    }

    public static func _set<Value>(
            _ pointer: UnsafeMutablePointer<Value>?,
            _ value: @autoclosure () throws -> Value) throws {
        guard let pointer else { throw COMError.pointer }
        pointer.pointee = try value()
    }
}
