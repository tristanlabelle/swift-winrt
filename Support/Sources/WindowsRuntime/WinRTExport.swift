import COM

/// Base for classes exported to WinRT and COM consumers.
open class WinRTExport<Projection: WinRTTwoWayProjection>
        : COMExport<Projection>, IInspectableProtocol {
    open class var _runtimeClassName: String { String(describing: Self.self) }
    open class var _trustLevel: TrustLevel { .base }
    open class var agile: Bool { true }
    open class var weakReferenceSource: Bool { true }

    public var inspectablePointer: IInspectableProjection.COMPointer {
        unknownPointer.withMemoryRebound(to: IInspectableProjection.COMInterface.self, capacity: 1) { $0 }
    }

    open override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        // QI for IInspectable should return the identity interface just like IUnknown.
        if id == IInspectableProjection.interfaceID { return unknownPointer.addingRef() }

        // Implement WinRT core interfaces
        if Self.agile && id == IAgileObjectProjection.interfaceID { return unknownPointer.addingRef() }
        if Self.weakReferenceSource && id == IWeakReferenceSourceProjection.interfaceID {
            let export = createSecondaryExport(
                projection: IWeakReferenceSourceProjection.self,
                implementation: WeakReferenceSource(target: self))
            return export.unknownPointer.addingRef()
        }

        return try super._queryInterfacePointer(id)
    }

    public override func createSecondaryExport<SecondaryProjection: COMTwoWayProjection>(
            projection: SecondaryProjection.Type,
            implementation: SecondaryProjection.SwiftObject) -> COMExport<SecondaryProjection> {
        WinRTWrappingExport<SecondaryProjection>(implementation: implementation, foreignIdentity: self)
    }

    open func getIids() throws -> [COMInterfaceID] {
        var iids = Self.implements.map { $0.id }
        if Self.agile { iids.append(IAgileObjectProjection.interfaceID) }
        if Self.weakReferenceSource { iids.append(IWeakReferenceSourceProjection.interfaceID) }
        return iids
    }

    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}

fileprivate final class WinRTWrappingExport<Projection: COMTwoWayProjection>: COMWrappingExport<Projection> {
    override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        // Delegate our identity
        if let foreignIdentity, id == IInspectableProjection.interfaceID { return foreignIdentity.unknownPointer.addingRef() }
        return try super._queryInterfacePointer(id)
    }

    public override func createSecondaryExport<SecondaryProjection: COMTwoWayProjection>(
            projection: SecondaryProjection.Type,
            implementation: SecondaryProjection.SwiftObject) -> COMExport<SecondaryProjection> {
        WinRTWrappingExport<SecondaryProjection>(implementation: implementation, foreignIdentity: self)
    }
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

    func _queryInterfacePointer(_ id: COM.COMInterfaceID) throws -> COM.IUnknownPointer {
        try target._queryInterfacePointer(id)
    }
}