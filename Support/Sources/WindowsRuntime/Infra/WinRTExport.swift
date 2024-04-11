import COM

/// Base for classes exported to WinRT and COM consumers.
open class WinRTPrimaryExport<Projection: InterfaceProjection>: COMPrimaryExport<Projection>, IInspectableProtocol {
    open class var _runtimeClassName: String { String(describing: Self.self) }
    open class var _trustLevel: TrustLevel { .base }
    open class var implementIStringable: Bool { true }
    open class var implementIWeakReferenceSource: Bool { true }

    public var inspectablePointer: IInspectableProjection.COMPointer {
        unknownPointer.withMemoryRebound(to: IInspectableProjection.COMInterface.self, capacity: 1) { $0 }
    }

    open override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        switch id {
            // QI for IInspectable should return the identity interface just like IUnknown.
            case IInspectableProjection.interfaceID:
                return .init(addingRef: unknownPointer)
            case IWeakReferenceSourceProjection.interfaceID where Self.implementIWeakReferenceSource:
                return ExportedWeakReferenceSource(target: self).toCOM().cast()
            case WindowsFoundation_IStringableProjection.interfaceID where Self.implementIStringable:
                if let customStringConvertible = self as? any CustomStringConvertible {
                    return ExportedStringable(implementation: customStringConvertible, identity: self).toCOM().cast()
                }
                break
            default: break
        }
        return try super._queryInterface(id)
    }

    open func getIids() throws -> [COMInterfaceID] {
        var iids = Self.implements.map { $0.id }
        if Self.implementIAgileObject { iids.append(IAgileObjectProjection.interfaceID) }
        if Self.implementIWeakReferenceSource { iids.append(IWeakReferenceSourceProjection.interfaceID) }
        if Self.implementIStringable, self is CustomStringConvertible { iids.append(WindowsFoundation_IStringableProjection.interfaceID) }
        return iids
    }

    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}

open class WinRTSecondaryExport<Projection: InterfaceProjection>: COMSecondaryExport<Projection>, IInspectableProtocol {
    public init(identity: IInspectable) {
        super.init(identity: identity)
    }

    // Delegate to the identity object, though we should be using that object's IInspectable implementation in the first place.
    public func getIids() throws -> [COMInterfaceID] { try (identity as! IInspectable).getIids() }
    public func getRuntimeClassName() throws -> String { try (identity as! IInspectable).getRuntimeClassName() }
    public func getTrustLevel() throws -> TrustLevel { try (identity as! IInspectable).getTrustLevel() }
}

fileprivate class ExportedStringable: WinRTSecondaryExport<WindowsFoundation_IStringableProjection>, WindowsFoundation_IStringableProtocol {
    private let implementation: any CustomStringConvertible

    init(implementation: any CustomStringConvertible, identity: IInspectable) {
        self.implementation = implementation
        super.init(identity: identity)
    }

    func toString() throws -> String { implementation.description }
}

fileprivate class ExportedWeakReferenceSource: COMSecondaryExport<IWeakReferenceSourceProjection>, IWeakReferenceSourceProtocol {
    init(target: IInspectable) { super.init(identity: target) }
    func getWeakReference() throws -> IWeakReference { ExportedWeakReference(target: identity as! IInspectable) }
}

fileprivate class ExportedWeakReference: COMPrimaryExport<IWeakReferenceProjection>, IWeakReferenceProtocol {
    weak var target: IInspectable?
    init(target: IInspectable) { self.target = target }
    func resolve() throws -> IInspectable? { target }
}