import COM

/// Base for classes exported to WinRT and COM consumers.
open class WinRTExport<Projection: WinRTTwoWayProjection>
        : COMExport<Projection>, IInspectableProtocol {
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
            case IInspectableProjection.interfaceID: return .init(addingRef: unknownPointer)
            case IWeakReferenceSourceProjection.interfaceID where Self.implementIWeakReferenceSource:
                let export = createSecondaryExport(
                    projection: IWeakReferenceSourceProjection.self,
                    implementation: WeakReferenceSource(target: self))
                return .init(addingRef: export.unknownPointer)
            case IStringableProjection.interfaceID where Self.implementIStringable:
                if let customStringConvertible = self as? any CustomStringConvertible {
                    let export = createSecondaryExport(
                        projection: IStringableProjection.self,
                        implementation: Stringable(target: customStringConvertible))
                    return .init(addingRef: export.unknownPointer)
                }
                break
            default: break
        }
        return try super._queryInterface(id)
    }

    public override func createSecondaryExport<SecondaryProjection: COMTwoWayProjection>(
            projection: SecondaryProjection.Type,
            implementation: SecondaryProjection.SwiftObject) -> COMExport<SecondaryProjection> {
        WinRTWrappingExport<SecondaryProjection>(implementation: implementation, foreignIdentity: self)
    }

    open func getIids() throws -> [COMInterfaceID] {
        var iids = Self.implements.map { $0.id }
        if Self.implementIAgileObject { iids.append(IAgileObjectProjection.interfaceID) }
        if Self.implementIWeakReferenceSource { iids.append(IWeakReferenceSourceProjection.interfaceID) }
        if Self.implementIStringable, self is CustomStringConvertible { iids.append(IStringableProjection.interfaceID) }
        return iids
    }

    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}

fileprivate final class WinRTWrappingExport<Projection: COMTwoWayProjection>: COMWrappingExport<Projection> {
    override func _queryInterface(_ id: COMInterfaceID) throws -> IUnknownReference {
        // Delegate our identity
        if let foreignIdentity, id == IInspectableProjection.interfaceID {
            return .init(addingRef: foreignIdentity.unknownPointer)
        }
        return try super._queryInterface(id)
    }

    public override func createSecondaryExport<SecondaryProjection: COMTwoWayProjection>(
            projection: SecondaryProjection.Type,
            implementation: SecondaryProjection.SwiftObject) -> COMExport<SecondaryProjection> {
        WinRTWrappingExport<SecondaryProjection>(implementation: implementation, foreignIdentity: self)
    }
}

fileprivate class Stringable: COMExport<IStringableProjection>, IStringableProtocol {
    private let target: any CustomStringConvertible
    init(target: any CustomStringConvertible) { self.target = target }
    func toString() throws -> String { target.description }
}

fileprivate class WeakReference: COMExport<IWeakReferenceProjection>, IWeakReferenceProtocol {
    weak var target: IInspectable?
    init(target: IInspectable) { self.target = target }
    func resolve() throws -> IInspectable? { target }
}

fileprivate class WeakReferenceSource: IWeakReferenceSourceProtocol {
    public let target: IInspectable
    init(target: IInspectable) { self.target = target }

    func getWeakReference() throws -> IWeakReference { WeakReference(target: target) }

    func _queryInterface(_ id: COM.COMInterfaceID) throws -> COM.IUnknownReference {
        try target._queryInterface(id)
    }
}