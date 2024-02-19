import COM

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
open class WinRTComposableClass: IInspectableProtocol {
    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var inner: IInspectablePointer // Strong ref'd

    /// The outer interface, for Swift-created instances which may override methods
    /// and which aggregate an inner pointer from WinRT as the base implementation.
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
                virtualTable: withUnsafePointer(to: &Self.outerVirtualTable) { $0 })

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
            var inner: IInspectablePointer? = nil
            defer { IInspectableProjection.release(&inner) }
            guard let composed = try _factory(nil, &inner) else { throw HResult.Error.fail }
            self.inner = IInspectablePointer.cast(composed)
            self.outer = .uninitialized
        }
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
        IUnknownPointer.release(inner)
    }

    public func _lazyInitInnerInterfacePointer<Interface>(_ pointer: inout UnsafeMutablePointer<Interface>?, _ id: COM.COMInterfaceID) throws -> UnsafeMutablePointer<Interface> {
        if let existing = pointer { return existing }
        let new = try IUnknownPointer.cast(inner).queryInterface(id).cast(to: Interface.self)
        pointer = new
        return new
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

        let implementation = COMExportedInterface.unwrap(this) as! SwiftObject
        return HResult.catchValue { try body(implementation) }
    }
}