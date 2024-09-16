import COM
import WindowsRuntime_ABI

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
///
/// There are three scenarios to support:
/// - Wrapping an existing WinRT object pointer
/// - Creating a new WinRT object, which does not need to support method overrides
/// - Creating a derived Swift class that can override methods
open class ComposableClass: IInspectableProtocol {
    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var innerWithRef: IInspectablePointer // Strong ref'd (not a COMReference<> because of initialization order issues)

    /// The outer object, which brokers QueryInterface calls between the inner object
    /// and any Swift overrides. This is only initialized for derived Swift classes.
    private var outer: COMEmbedding

    /// Initializer for instances created in WinRT
    public init(_wrapping inner: consuming IInspectableReference) {
        innerWithRef = inner.detach()
        // The pointer comes from WinRT so we don't have any overrides and there is no outer object.
        // All methods will delegate to the inner object (in this case the full object).
        outer = .uninitialized
    }

    public typealias ComposableFactory<ABIStruct> = (
        _ outer: IInspectablePointer?,
        _ inner: inout IInspectablePointer?) throws -> COMReference<ABIStruct>

    /// Initializer for instances created in Swift
    /// - Parameter _compose: Whether to create a composed object that supports method overrides in Swift.
    /// - Parameter _factory: A closure calling the WinRT composable activation factory method.
    public init<ABIStruct>(_compose: Bool, _factory: ComposableFactory<ABIStruct>) throws {
        if _compose {
            // Workaround Swift initialization rules:
            // - Factory needs an initialized outer pointer pointing to self
            // - self.inner needs to be initialized before being able to reference self
            self.outer = .uninitialized
            self.innerWithRef = IInspectablePointer(OpaquePointer(outer.unknownPointer)) // We need to assign inner to something, it doesn't matter what.
            self.outer.initialize(embedder: self, virtualTable: IInspectableBinding.virtualTablePointer)

            // Like C++/WinRT, discard the returned composed object and only use the inner object
            // The composed object is useful only when not providing an outer object.
            var inner: IInspectablePointer? = nil
            _ = try _factory(IInspectablePointer(OpaquePointer(outer.unknownPointer)), &inner)
            guard let inner else { throw COMError.fail }
            self.innerWithRef = inner
        }
        else {
            // We're not overriding any methods so we don't need to provide an outer object.
            outer = .uninitialized

            // We don't care about the inner object since WinRT provides us with the composed object.
            var inner: IInspectablePointer? = nil
            defer { IInspectableBinding.release(&inner) }
            self.innerWithRef = try _factory(nil, &inner).cast().detach()
        }
    }

    deinit {
        COMInterop(innerWithRef).release()
    }

    open class var implements: [COMImplements] { [] }

    public func _queryInnerInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).queryInterface(id)
    }

    open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        // If we are a composed object create from Swift, act as such
        if outer.isInitialized {
            // We own the identity, don't delegate to the inner object.
            if id == IUnknownBinding.interfaceID || id == IInspectableBinding.interfaceID {
                return outer.toCOM()
            }

            // Check for overrides.
            if let overrides = try _queryOverridesInterface(id).finalDetach() {
                return .init(transferringRef: overrides)
            }

            // Check for additional implemented interfaces.
            if let interface = Self.implements.first(where: { $0.id == id }) {
                return interface.createCOM(identity: self)
            }
        }

        // Delegate to the inner object.
        return try _queryInnerInterface(id)
    }

    open func _queryOverridesInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference.Optional { .none }

    open func getIids() throws -> [COM.COMInterfaceID] {
        // Workaround for 5.9 compiler bug when using inner.interop directly:
        // "error: copy of noncopyable typed value. This is a compiler bug"
        try COMInterop(innerWithRef).getIids() + Self.implements.map { $0.id }
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