import COM

/// Base for classes exported to WinRT and COM consumers.
open class WinRTPrimaryExport<Binding: InterfaceBinding>: COMPrimaryExport<Binding>, IInspectableProtocol {
    open class var _runtimeClassName: String { String(describing: Self.self) }
    open class var _trustLevel: TrustLevel { .base }
    open class var implementIStringable: Bool { true }
    open class var implementIWeakReferenceSource: Bool { true }

    public var inspectablePointer: IInspectableBinding.ABIPointer {
        unknownPointer.withMemoryRebound(to: IInspectableBinding.ABIStruct.self, capacity: 1) { $0 }
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            // QI for IInspectable should return the identity interface just like IUnknown.
            case IInspectableBinding.interfaceID:
                return .init(addingRef: unknownPointer)
            case IWeakReferenceSourceBinding.interfaceID where Self.implementIWeakReferenceSource:
                return ExportedWeakReferenceSource(target: self).toCOM().cast()
            case WindowsFoundation_IStringableBinding.interfaceID where Self.implementIStringable:
                if let customStringConvertible = self as? any CustomStringConvertible {
                    return ExportedStringable(implementation: customStringConvertible, identity: self).toCOM().cast()
                }
                break
            default: break
        }
        return try super._queryInterface(id)
    }

    open func getIids() throws -> [COMInterfaceID] {
        var iids = [COMInterfaceID]()
        try _appendIids(&iids)
        return iids
    }

    open func _appendIids(_ iids: inout [COMInterfaceID]) throws {
        for interfaceBinding in Self.queriableInterfaces { iids.append(interfaceBinding.interfaceID) }
        if Self.implementIAgileObject { iids.append(IAgileObjectBinding.interfaceID) }
        if Self.implementIWeakReferenceSource { iids.append(IWeakReferenceSourceBinding.interfaceID) }
        if Self.implementIStringable, self is CustomStringConvertible { iids.append(WindowsFoundation_IStringableBinding.interfaceID) }
    }

    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}

open class WinRTSecondaryExport<Binding: InterfaceBinding>: COMSecondaryExport<Binding>, IInspectableProtocol {
    public init(identity: IInspectable) {
        super.init(identity: identity)
    }

    // Delegate to the identity object, though we should be using that object's IInspectable implementation in the first place.
    public func getIids() throws -> [COMInterfaceID] { try (identity as! IInspectable).getIids() }
    public func getRuntimeClassName() throws -> String { try (identity as! IInspectable).getRuntimeClassName() }
    public func getTrustLevel() throws -> TrustLevel { try (identity as! IInspectable).getTrustLevel() }
}

fileprivate class ExportedStringable: WinRTSecondaryExport<WindowsFoundation_IStringableBinding>, WindowsFoundation_IStringableProtocol {
    private let implementation: any CustomStringConvertible

    init(implementation: any CustomStringConvertible, identity: IInspectable) {
        self.implementation = implementation
        super.init(identity: identity)
    }

    func toString() throws -> String { implementation.description }
}

fileprivate class ExportedWeakReferenceSource: COMSecondaryExport<IWeakReferenceSourceBinding>, IWeakReferenceSourceProtocol {
    init(target: IInspectable) { super.init(identity: target) }
    func getWeakReference() throws -> IWeakReference { ExportedWeakReference(target: identity as! IInspectable) }
}

fileprivate class ExportedWeakReference: COMPrimaryExport<IWeakReferenceBinding>, IWeakReferenceProtocol {
    weak var target: IInspectable?
    init(target: IInspectable) { self.target = target }
    func resolve() throws -> IInspectable? { target }
}