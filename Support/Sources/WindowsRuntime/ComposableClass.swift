import COM
import COM_ABI
import WindowsRuntime_ABI

/// Base class for composable (unsealed) WinRT classes, implemented using COM aggregration.
///
/// There are three scenarios to support:
/// - Wrapping an existing WinRT object pointer
/// - Creating a new WinRT object, which does not need to support method overrides
/// - Creating a derived Swift class that can override methods
open class ComposableClass: IInspectableProtocol {
    /// Return true to support overriding WinRT methods in Swift (incurs a size and perf overhead).
    open class var supportsOverrides: Bool { true }

    open class var queriableInterfaces: [any COMTwoWayBinding.Type] { [] }

    /// The inner pointer, which comes from WinRT and implements the base behavior (without overriden methods).
    private var innerObjectWithRef: IInspectablePointer // Strong ref'd (not a COMReference<> because of initialization order issues)

    /// The outer object, if we are a composed object created from Swift.
    private var outerObject: OuterObject?

    /// Initializer for instances created in WinRT
    public init(_wrapping innerObject: consuming IInspectableReference) {
        innerObjectWithRef = innerObject.detach()
        // The pointer comes from WinRT so we don't have any overrides and there is no outer object.
        // All methods will delegate to the inner object (in this case the full object).
        outerObject = nil
    }

    public typealias ComposableFactory<ABIStruct> = (
        _ outer: IInspectablePointer?,
        _ inner: inout IInspectablePointer?) throws -> COMReference<ABIStruct>

    /// Initializer for instances created in Swift
    /// - Parameter _outer: The outer object, which brokers QueryInterface calls to the inner object.
    /// - Parameter _factory: A closure calling the WinRT composable activation factory method.
    public init<ABIStruct>(_outer: OuterObject.Type, _factory: ComposableFactory<ABIStruct>) throws {
        if Self.supportsOverrides {
            // Dummy initialization to satisfy Swift's initialization rules
            self.outerObject = nil
            self.innerObjectWithRef = IInspectablePointer(OpaquePointer(bitPattern: 0xDEADBEEF)!) // We need to assign inner to something, it doesn't matter what.

            let outerObject = _outer.init(owner: self)

            // Like C++/WinRT, discard the returned composed object and only use the inner object
            // The composed object is useful only when not providing an outer object.
            var innerObjectWithRef: IInspectablePointer? = nil
            _ = try _factory(IInspectablePointer(OpaquePointer(outerObject.comEmbedding.asUnknownPointer())), &innerObjectWithRef)
            guard let innerObjectWithRef else { throw COMError.fail }
            self.innerObjectWithRef = innerObjectWithRef
            self.outerObject = outerObject
        }
        else {
            // We don't care about the inner object since WinRT provides us with the composed object.
            var innerObjectWithRef: IInspectablePointer? = nil
            defer { IInspectableBinding.release(&innerObjectWithRef) }
            self.innerObjectWithRef = try _factory(nil, &innerObjectWithRef).cast().detach()

            // We're not overriding any methods so we don't need to provide an outer object.
            outerObject = nil
        }
    }

    deinit {
        COMInterop(innerObjectWithRef).release()
    }

    public func _queryInnerInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        try COMInterop(innerObjectWithRef).queryInterface(id)
    }

    open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        if let outerObject {
            return try outerObject._queryInterface(id)
        } else {
            return try _queryInnerInterface(id)
        }
    }

    open func getIids() throws -> [COM.COMInterfaceID] {
        try COMInterop(innerObjectWithRef).getIids() + Self.queriableInterfaces.map { $0.interfaceID }
    }

    open func getRuntimeClassName() throws -> String {
        try COMInterop(innerObjectWithRef).getRuntimeClassName()
    }

    open func getTrustLevel() throws -> WindowsRuntime.TrustLevel {
        try COMInterop(innerObjectWithRef).getTrustLevel()
    }

    /// Base class for the outer object, which brokers QueryInterface calls to the inner object.
    open class OuterObject: IUnknownProtocol {
        // The embedder pointer points to the owner ComposableClass object,
        // which transitively keeps us alive.
        fileprivate var comEmbedding: COMEmbedding

        public required init(owner: ComposableClass) {
            self.comEmbedding = .init(virtualTable: IInspectableBinding.virtualTablePointer, embedder: nil)
            self.comEmbedding.initEmbedder(owner)
        }

        open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
            // We own the identity, don't delegate to the inner object.
            if id == IUnknownBinding.interfaceID || id == IInspectableBinding.interfaceID {
                return comEmbedding.toCOM()
            }

            let owner = comEmbedding.embedder as! ComposableClass

            // Check for additional implemented interfaces.
            if let interfaceBinding = type(of: owner).queriableInterfaces.first(where: { $0.interfaceID == id }) {
                return COMDelegatingTearOff(virtualTable: interfaceBinding.virtualTablePointer, owner: owner).toCOM()
            }

            return try owner._queryInnerInterface(id)
        }
    }
}