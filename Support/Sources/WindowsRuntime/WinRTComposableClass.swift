import COM
import WindowsRuntime_ABI

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
///
/// There are three scenarios to support:
/// - Wrapping an existing WinRT object pointer
/// - Creating a new WinRT object, which does not need to support method overrides
/// - Creating a derived Swift class that can override methods
open class WinRTComposableClass: IInspectableProtocol {
    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var inner: IInspectableReference

    /// The outer object, which brokers QueryInterface calls between the inner object
    /// and any Swift overrides. This is only initialized for derived Swift classes.
    private var outer: COMExportedInterface

    /// Initializer for instances created in WinRT
    public init(_wrapping reference: consuming IInspectableReference) {
        inner = reference
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
            // Create the inner object using a valid pointer to an uninitialized outer object.
            var inner: IInspectablePointer? = nil
            self.outer = .uninitialized
            let composed: UnsafeMutablePointer<Interface>? = try _factory(IInspectablePointer.cast(outer.unknownPointer), &inner)

            // Like C++/WinRT, discard the composed object and only use the inner object
            // See "[[maybe_unused]] auto winrt_impl_discarded = f.CreateInstance(*this, this->minner);"
            // The composed object is useful when not providing an outer object.
            IUnknownPointer.release(composed)

            guard let inner else { throw HResult.Error.fail }
            self.inner = .init(transferringRef: inner)

            // We can now reference self, so initialize the outer object.
            self.outer = .init(
                swiftObject: self,
                virtualTable: IInspectableProjection.virtualTablePointer)
        }
        else {
            // We're not overriding any methods, so create a vanilla composed object to avoid indirections.
            outer = .uninitialized

            var inner: IInspectablePointer? = nil
            defer { IInspectableProjection.release(&inner) }
            guard let composed = try _factory(nil, &inner) else { throw HResult.Error.fail }
            self.inner = .init(transferringRef: IInspectablePointer.cast(composed))
        }
    }

    // Workaround for 5.9 compiler bug when using inner.interop directly:
    // "error: copy of noncopyable typed value. This is a compiler bug"
    private var innerInterop: COMInterop<WindowsRuntime_ABI.SWRT_IInspectable> {
        COMInterop(inner.pointer)
    }

    public func _queryInnerInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        try innerInterop.queryInterface(id)
    }

    open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        // If we are a composed object create from Swift, we may have overrides.
        if outer.isInitialized, let overrides = try _queryOverridesInterfacePointer(id) {
            return .init(addingRef: overrides)
        }

        // Delegate to the inner object.
        return try _queryInnerInterface(id)
    }

    open func _queryOverridesInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer? { nil }

    open func getIids() throws -> [COM.COMInterfaceID] {
        try innerInterop.getIids()
    }

    open func getRuntimeClassName() throws -> String {
        try innerInterop.getRuntimeClassName()
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        try innerInterop.getTrustLevel()
    }
}