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
    private var innerWithRef: IInspectablePointer // Strong ref'd (not a COMReference<> because of initialization order issues)

    /// The outer object, which brokers QueryInterface calls between the inner object
    /// and any Swift overrides. This is only initialized for derived Swift classes.
    private var outer: COMExportedInterface

    /// Initializer for instances created in WinRT
    // Should take a COMReference<>, but this runs into cmopiler bugs.
    public init(_transferringRef pointer: IInspectablePointer) {
        innerWithRef = pointer
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
            // Workaround Swift initialization rules:
            // - Factory needs an initialized outer pointer pointing to self
            // - self.inner needs to be initialized before being able to reference self
            self.outer = .uninitialized
            self.innerWithRef = IInspectablePointer(OpaquePointer(outer.unknownPointer)) // We need to assign inner to something, it doesn't matter what.
            self.outer = .init(swiftObject: self, virtualTable: IInspectableProjection.virtualTablePointer)

            // Like C++/WinRT, discard the returned composed object and only use the inner object
            // The composed object is useful only when not providing an outer object.
            var inner: IInspectablePointer? = nil
            let composed = try _factory(IInspectablePointer(OpaquePointer(outer.unknownPointer)), &inner)
            if let composed { COMInterop(composed).release() }
            guard let inner else { throw HResult.Error.fail }
            self.innerWithRef = inner
        }
        else {
            // We're not overriding any methods so we don't need to provide an outer object.
            outer = .uninitialized

            // We don't care about the inner object since WinRT provides us with the composed object.
            var inner: IInspectablePointer? = nil
            defer { IInspectableProjection.release(&inner) }
            guard let composed = try _factory(nil, &inner) else { throw HResult.Error.fail }
            self.innerWithRef = IInspectablePointer(OpaquePointer(composed))
        }
    }

    deinit {
        COMInterop(innerWithRef).release()
    }

    public func _queryInnerInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).queryInterface(id)
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
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).getIids()
    }

    open func getRuntimeClassName() throws -> String {
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).getRuntimeClassName()
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).getTrustLevel()
    }
}