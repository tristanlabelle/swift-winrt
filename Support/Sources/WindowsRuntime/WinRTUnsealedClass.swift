import COM

/// Base class for unsealed WinRT classes, implemented using COM aggregration.
open class WinRTUnsealedClass: IInspectableProtocol {
    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var _inner: IInspectablePointer // Strong ref'd

    /// The outer interface, for Swift-created instances which may override methods
    /// and which aggregate an inner pointer from WinRT as the base implementation.
    private var _outer: COMExportedInterface

    /// Initializer for instances created in WinRT
    public init(_consumingCOMPointer comPointer: IInspectablePointer) {
        _inner = comPointer
        // The pointer comes from WinRT so we don't have any overrides and there is no outer object.
        // All methods will delegate to the inner object (in this case the full object).
        _outer = .uninitialized
    }

    public typealias ComposableFactory<Interface> = (
        _ outer: IInspectablePointer,
        _ inner: UnsafeMutablePointer<IInspectablePointer?>,
        _ value: UnsafeMutablePointer<UnsafeMutablePointer<Interface>?>) -> HResultProjection.ABIValue

    /// Initializer for instances created in Swift
    public init<Interface>(_factory: ComposableFactory<Interface>) throws {
        // Dummy-initialize all fields so we can reference "self"
        _outer = .uninitialized
        _inner = IInspectablePointer.cast(_outer.unknownPointer)

        // Reinitialize the outer object correctly
        _outer = .init(
            swiftObject: self,
            virtualTable: withUnsafePointer(to: &Self.outerVirtualTable) { $0 })

        // Create the inner object
        var inner: IInspectablePointer? = nil
        var composed: UnsafeMutablePointer<Interface>? = nil
        try WinRTError.throwIfFailed(_factory(IInspectablePointer.cast(_outer.unknownPointer), &inner, &composed))

        // Like C++/WinRT, discard the composed object and only use the inner object
        // See "[[maybe_unused]] auto winrt_impl_discarded = f.CreateInstance(*this, this->m_inner);"
        IUnknownPointer.release(composed)

        guard let inner else { throw HResult.Error.fail }
        _inner = inner
    }

    // Virtual table for the outer IInspectable object, which calls methods on the Swift object, allowing overriding
    private static var outerVirtualTable: IInspectableProjection.COMVirtualTable = .init(
        QueryInterface: { COMExportedInterface.QueryInterface($0, $1, $2) },
        AddRef: { COMExportedInterface.AddRef($0) },
        Release: { COMExportedInterface.Release($0) },
        GetIids: { WinRTExportedInterface.GetIids($0, $1, $2) },
        GetRuntimeClassName: { WinRTExportedInterface.GetRuntimeClassName($0, $1) },
        GetTrustLevel: { WinRTExportedInterface.GetTrustLevel($0, $1) })

    deinit {
        IUnknownPointer.release(_inner)
    }

    public func _lazyInitInnerInterfacePointer<Interface>(_ pointer: inout UnsafeMutablePointer<Interface>?, _ id: COM.COMInterfaceID) throws -> UnsafeMutablePointer<Interface> {
        if let existing = pointer { return existing }
        let new = try IUnknownPointer.cast(_inner).queryInterface(id).withMemoryRebound(to: Interface.self, capacity: 1) { $0 }
        pointer = new
        return new
    }

    open func _queryInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer {
        // If we are a composed object create from Swift, we may have overrides.
        if _outer.isInitialized, let overrides = try _queryOverridesInterfacePointer(id) {
            return overrides
        }

        // Delegate to the inner object.
        return try IUnknownPointer.cast(_inner).queryInterface(id)
    }

    open func _queryOverridesInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer? { nil }

    open func getIids() throws -> [COM.COMInterfaceID] {
        var value: COMArray<COM.GUIDProjection.ABIValue> = .init()
        try WinRTError.throwIfFailed(_inner.pointee.lpVtbl.pointee.GetIids(_inner, &value.count, &value.pointer))
        return WinRTArrayProjection<COM.GUIDProjection>.toSwift(consuming: &value)
    }

    open func getRuntimeClassName() throws -> String {
        var value: HStringProjection.ABIValue = nil
        try WinRTError.throwIfFailed(_inner.pointee.lpVtbl.pointee.GetRuntimeClassName(_inner, &value))
        return HStringProjection.toSwift(consuming: &value)
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        var value: TrustLevel.ABIValue = .init()
        try WinRTError.throwIfFailed(_inner.pointee.lpVtbl.pointee.GetTrustLevel(_inner, &value))
        return TrustLevel.toSwift(value)
    }

    /// Helper to implement virtual table methods for the outer object.
    public static func _implement<Interface, SwiftObject: AnyObject>(
            _ this: UnsafeMutablePointer<Interface>?, type: SwiftObject.Type,
            _ body: (SwiftObject) throws -> Void) -> HResultProjection.ABIValue {
        guard let this else {
            assertionFailure("COM this pointer was null")
            return HResult.pointer.value
        }

        let implementation = COMExportedInterface.unwrap(this) as! SwiftObject
        return HResult.catchValue { try body(implementation) }
    }
}