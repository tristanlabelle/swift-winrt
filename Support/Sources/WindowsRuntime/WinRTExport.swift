import COM

/// Base for classes exported to WinRT and COM consumers.
open class WinRTExport<PrimaryInterfaceBinding: InterfaceBinding>: COMExport<PrimaryInterfaceBinding>, IInspectableProtocol {
    open class var _runtimeClassName: String { String(describing: Self.self) }
    open class var _trustLevel: TrustLevel { .base }
    open class var implementIStringable: Bool { true }
    open class var implementIWeakReferenceSource: Bool { true }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            // QI for IInspectable should return the identity interface just like IUnknown.
            case IInspectableBinding.interfaceID:
                return toCOM().cast()
            case IWeakReferenceSourceBinding.interfaceID where Self.implementIWeakReferenceSource:
                return WeakReferenceSourceTearOff(owner: self).toCOM().cast()
            case WindowsFoundation_IStringableBinding.interfaceID where Self.implementIStringable:
                if let customStringConvertible = self as? any CustomStringConvertible {
                    return StringableTearOff(owner: self, implementation: customStringConvertible).toCOM().cast()
                }
                break
            default: break
        }
        return try super._queryInterface(id)
    }

    open func getIids() throws -> [COMInterfaceID] {
        var iids = Self.queriableInterfaces.map { $0.interfaceID }
        if Self.implementIAgileObject { iids.append(IAgileObjectBinding.interfaceID) }
        if Self.implementIWeakReferenceSource { iids.append(IWeakReferenceSourceBinding.interfaceID) }
        if Self.implementIStringable, self is CustomStringConvertible { iids.append(WindowsFoundation_IStringableBinding.interfaceID) }
        return iids
    }

    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}

open class WinRTTearOff<Binding: InterfaceBinding>: COMTearOff<Binding>, IInspectableProtocol {
    public init(owner: IInspectable) {
        super.init(owner: owner)
    }

    // Delegate to the identity object, though we should be using that object's IInspectable implementation in the first place.
    public func getIids() throws -> [COMInterfaceID] { try (owner as! IInspectable).getIids() }
    public func getRuntimeClassName() throws -> String { try (owner as! IInspectable).getRuntimeClassName() }
    public func getTrustLevel() throws -> TrustLevel { try (owner as! IInspectable).getTrustLevel() }
}

fileprivate class StringableTearOff: WinRTTearOff<WindowsFoundation_IStringableBinding>, WindowsFoundation_IStringableProtocol {
    private let implementation: any CustomStringConvertible

    init(owner: IInspectable, implementation: any CustomStringConvertible) {
        self.implementation = implementation
        super.init(owner: owner)
    }

    func toString() throws -> String { implementation.description }
}

fileprivate class WeakReferenceSourceTearOff: COMTearOff<IWeakReferenceSourceBinding>, IWeakReferenceSourceProtocol {
    init(owner: IInspectable) { super.init(owner: owner) }
    func getWeakReference() throws -> IWeakReference { ExportedWeakReference(target: owner as! IInspectable) }
}

fileprivate class ExportedWeakReference: COMExport<IWeakReferenceBinding>, IWeakReferenceProtocol {
    weak var target: IInspectable?
    init(target: IInspectable) { self.target = target }
    func resolve() throws -> IInspectable? { target }
}