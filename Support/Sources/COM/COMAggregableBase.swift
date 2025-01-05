import COM_ABI

/// Base class for aggregable COM objects.
///
/// There are three scenarios to support:
/// - Wrapping an existing COM object pointer
/// - Creating a new COM object, which does not need to support method overrides
/// - Creating a derived Swift class that can override methods
open class COMAggregableBase: IUnknownProtocol {
    /// Return true to support overriding COM methods in Swift (incurs a size and perf overhead).
    open class var supportsOverrides: Bool { true }

    open class var queriableInterfaces: [any COMTwoWayBinding.Type] { [] }

    /// The inner pointer, which comes from COM and implements the base behavior (without overriden methods).
    private var _innerObjectWithRef: IUnknownPointer // Strong ref'd (not a COMReference<> because of initialization order issues)

    public var _innerObject: COMInterop<SWRT_IUnknown> { .init(_innerObjectWithRef) }

    /// The outer object, if we are a composed object created from Swift.
    public private(set) var _outerObject: OuterObject?

    /// Initializer for instances created by COM
    public init(_wrapping innerObject: consuming IUnknownReference) {
        _innerObjectWithRef = innerObject.detach()
        // The pointer comes from COM so we don't have any overrides and there is no outer object.
        // All methods will delegate to the inner object (in this case the full object).
        _outerObject = nil
    }

    public typealias Factory<ABIStruct> = (
        _ outer: IUnknownPointer?,
        _ inner: inout IUnknownPointer?) throws -> COMReference<ABIStruct>

    /// Initializer for instances created in Swift
    /// - Parameter _outer: The outer object, which brokers QueryInterface calls to the inner object.
    /// - Parameter _factory: A closure calling the COM factory method.
    public init<ABIStruct>(_outer: OuterObject.Type, _factory: Factory<ABIStruct>) throws {
        if Self.supportsOverrides {
            // Dummy initialization to satisfy Swift's initialization rules
            self._outerObject = nil
            self._innerObjectWithRef = IUnknownPointer(OpaquePointer(bitPattern: 0xDEADBEEF)!) // We need to assign inner to something, it doesn't matter what.

            let outerObject = _outer.init(owner: self)

            // Like C++/WinRT, discard the returned composed object and only use the inner object
            // The composed object is useful only when not providing an outer object.
            var innerObjectWithRef: IUnknownPointer? = nil
            _ = try _factory(IUnknownPointer(OpaquePointer(outerObject.comEmbedding.asUnknownPointer())), &innerObjectWithRef)
            guard let innerObjectWithRef else { throw COMError.fail }
            self._innerObjectWithRef = innerObjectWithRef
            self._outerObject = outerObject
        }
        else {
            // We don't care about the inner object since COM provides us with the composed object.
            var innerObjectWithRef: IUnknownPointer? = nil
            defer { IUnknownBinding.release(&innerObjectWithRef) }
            self._innerObjectWithRef = try _factory(nil, &innerObjectWithRef).cast().detach()

            // We're not overriding any methods so we don't need to provide an outer object.
            self._outerObject = nil
        }
    }

    deinit {
        _innerObject.release()
    }

    public func _queryInnerInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        try _innerObject.queryInterface(id)
    }

    open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        if let _outerObject {
            return try _outerObject._queryInterface(id)
        } else {
            return try _queryInnerInterface(id)
        }
    }

    /// Base class for the outer object, which brokers QueryInterface calls to the inner object.
    open class OuterObject: IUnknownProtocol {
        open class var exportedVirtualTable: VirtualTablePointer { IUnknownBinding.exportedVirtualTable }

        // The owner pointer points to the ComposableClass object,
        // which transitively keeps us alive.
        fileprivate var comEmbedding: COMEmbedding

        public var owner: COMAggregableBase { comEmbedding.owner as! COMAggregableBase }

        public required init(owner: COMAggregableBase) {
            self.comEmbedding = .init(virtualTable: Self.exportedVirtualTable, owner: nil)
            self.comEmbedding.initOwner(owner)
        }

        public func toCOM() -> COM.IUnknownReference {
            comEmbedding.toCOM()
        }

        open func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
            // We own the identity, don't delegate to the inner object.
            if id == IUnknownBinding.interfaceID {
                return toCOM()
            }

            // Check for additional implemented interfaces.
            if let interfaceBinding = type(of: owner).queriableInterfaces.first(where: { $0.interfaceID == id }) {
                return COMDelegatingTearOff(owner: owner, virtualTable: interfaceBinding.exportedVirtualTable).toCOM()
            }

            return try owner._queryInnerInterface(id)
        }
    }
}