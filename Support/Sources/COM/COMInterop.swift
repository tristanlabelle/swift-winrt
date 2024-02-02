import CWinRTCore

/// Wraps a COM interface pointer and exposes projected versions of its methods.
/// This struct is extended with methods for each COM interface it wraps.
public struct COMInterop<Interface> {
    public let _pointer: UnsafeMutablePointer<Interface>

    public init(_ pointer: UnsafeMutablePointer<Interface>) {
        self._pointer = pointer
    }

    public static func cast<Source>(_ source: COMInterop<Source>) -> COMInterop<Interface> {
        COMInterop<Interface>(source._pointer.withMemoryRebound(to: Interface.self, capacity: 1) { $0 })
    }

    private var _unknownPointer: UnsafeMutablePointer<CWinRTCore.SWRT_IUnknown>{
        _pointer.withMemoryRebound(to: CWinRTCore.SWRT_IUnknown.self, capacity: 1) { $0 }
    }

    @discardableResult
    public func addRef() -> UInt32 {
        _unknownPointer.pointee.lpVtbl.pointee.AddRef(_unknownPointer)
    }

    @discardableResult
    public func release() -> UInt32 {
        _unknownPointer.pointee.lpVtbl.pointee.Release(_unknownPointer)
    }

    public func queryInterface(_ id: COMInterfaceID) throws -> IUnknownPointer {
        var iid = GUIDProjection.toABI(id)
        var pointer: UnsafeMutableRawPointer? = nil
        try HResult.throwIfFailed(_unknownPointer.pointee.lpVtbl.pointee.QueryInterface(_unknownPointer, &iid, &pointer))
        guard let pointer else {
            assertionFailure("QueryInterface succeeded but returned a null pointer")
            throw HResult.Error.noInterface
        }

        return pointer.bindMemory(to: CWinRTCore.SWRT_IUnknown.self, capacity: 1)
    }
}