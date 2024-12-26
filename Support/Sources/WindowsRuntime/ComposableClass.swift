import COM
import COM_ABI
import WindowsRuntime_ABI

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
open class ComposableClass: COMAggregableBase, IInspectableProtocol {
    /// Initializer for instances created in WinRT.
    public init(_wrapping innerObject: consuming IInspectableReference) {
        super.init(_wrapping: innerObject.cast())
    }

    public typealias ComposableFactory<ABIStruct> = (
        _ outer: IInspectablePointer?,
        _ inner: inout IInspectablePointer?) throws -> COMReference<ABIStruct>

    /// Initializer for instances created in Swift
    /// - Parameter _outer: The outer object, which brokers QueryInterface calls to the inner object.
    /// - Parameter _factory: A closure calling the WinRT composable activation factory method.
    public init<ABIStruct>(_outer: OuterObject.Type, _factory: ComposableFactory<ABIStruct>) throws {
        try super.init(_outer: _outer) {
            var inner: IInspectablePointer? = nil
            do {
                let result = try _factory($0.map { IInspectablePointer(OpaquePointer($0)) }, &inner)
                $1 = IUnknownPointer(OpaquePointer(inner))
                return result
            } catch {
                $1 = IUnknownPointer(OpaquePointer(inner))
                throw error
            }
        }
    }

    private var _innerInspectable: COMInterop<SWRT_IInspectable> { .init(casting: _innerObject) }

    open func getIids() throws -> [COM.COMInterfaceID] {
        try _innerInspectable.getIids() + Self.queriableInterfaces.map { $0.interfaceID }
    }

    open func getRuntimeClassName() throws -> String {
        try _innerInspectable.getRuntimeClassName()
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        try _innerInspectable.getTrustLevel()
    }

    /// Base class for the outer object, which brokers QueryInterface calls to the inner object.
    open class OuterObject: COMAggregableBase.OuterObject {
        open override class var virtualTable: UnsafeRawPointer { IInspectableBinding.virtualTablePointer }

        open override func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
            // We own the identity, don't delegate to the inner object.
            if id == IInspectableBinding.interfaceID { return toCOM() }
            return try super._queryInterface(id)
        }
    }
}