import COM

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
///
/// There are three scenarios to support:
/// - Wrapping an existing WinRT object pointer
/// - Creating a new WinRT object, which does not need to support method overrides
/// - Creating a derived Swift class that can override methods
open class WinRTComposableClass: IInspectableProtocol {
    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var inner: IInspectablePointer // Strong ref'd

    /// The outer object, which brokers QueryInterface calls between the inner object
    /// and any Swift overrides. This is only initialized for derived Swift classes.
    private var outer: COMExportedInterface

    /// Initializer for instances created in WinRT
    public init(_transferringRef comPointer: IInspectablePointer) {
        inner = comPointer
        // The pointer comes from WinRT so we don't have any overrides and there is no outer object.
        // All methods will delegate to the inner object (in this case the full object).
        outer = .uninitialized
    }

    public typealias ComposableFactory<Interface> = (
        _ outer: IInspectablePointer?,
        _ inner: inout IInspectablePointer?) throws -> UnsafeMutablePointer<Interface>?

    /// Initializer for instances created in Swift
    /// - Parameter _compose: Whether to create a composed object that supports method overrides in Swift.
    /// - Parameter _factory: A closure calling the WinRT composable activation factory method.
    public init<Interface>(_compose: Bool, _factory: ComposableFactory<Interface>) throws {
        if _compose {
            // We're overriding methods, so create the outer object to be composed.
            // Dummy-initialize all fields so we can reference "self"
            outer = .uninitialized
            inner = IInspectablePointer.cast(outer.unknownPointer)

            // Reinitialize the outer object correctly
            outer = .init(
                swiftObject: self,
                virtualTable: IInspectableProjection.virtualTablePointer)

            // Create the inner object
            var inner: IInspectablePointer? = nil
            let composed: UnsafeMutablePointer<Interface>? = try _factory(IInspectablePointer.cast(outer.unknownPointer), &inner)

            // Like C++/WinRT, discard the composed object and only use the inner object
            // See "[[maybe_unused]] auto winrt_impl_discarded = f.CreateInstance(*this, this->minner);"
            // The composed object is useful when not providing an outer object.
            IUnknownPointer.release(composed)

            guard let inner else { throw HResult.Error.fail }
            self.inner = inner
        }
        else {
            // We're not overriding any methods, so create a vanilla composed object to avoid indirections.
            outer = .uninitialized

            var inner: IInspectablePointer? = nil
            defer { IInspectableProjection.release(&inner) }
            guard let composed = try _factory(nil, &inner) else { throw HResult.Error.fail }
            self.inner = IInspectablePointer.cast(composed)
        }
    }

    deinit {
        IUnknownPointer.release(inner)
    }

    public func _queryInnerInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer {
        try IUnknownPointer.cast(inner).queryInterface(id)
    }

    open func _queryInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer {
        // If we are a composed object create from Swift, we may have overrides.
        if outer.isInitialized, let overrides = try _queryOverridesInterfacePointer(id) {
            return overrides
        }

        // Delegate to the inner object.
        return try IUnknownPointer.cast(inner).queryInterface(id)
    }

    open func _queryOverridesInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer? { nil }

    open func getIids() throws -> [COM.COMInterfaceID] {
        var value: COMArray<COM.GUIDProjection.ABIValue> = .init()
        try WinRTError.throwIfFailed(inner.pointee.lpVtbl.pointee.GetIids(inner, &value.count, &value.pointer))
        return WinRTArrayProjection<COM.GUIDProjection>.toSwift(consuming: &value)
    }

    open func getRuntimeClassName() throws -> String {
        var value: HStringProjection.ABIValue = nil
        try WinRTError.throwIfFailed(inner.pointee.lpVtbl.pointee.GetRuntimeClassName(inner, &value))
        return HStringProjection.toSwift(consuming: &value)
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        var value: TrustLevel.ABIValue = .init()
        try WinRTError.throwIfFailed(inner.pointee.lpVtbl.pointee.GetTrustLevel(inner, &value))
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

        let implementation = COMExportedInterface.unwrapUnsafe(this) as! SwiftObject
        return HResult.catchValue { try body(implementation) }
    }
}