import COM

/// Base for classes exported to WinRT.
open class WinRTExportedObject<Projection: WinRTTwoWayProjection>
        : COMExportedObject<Projection>, IInspectableProtocol {
    public init(
            implementation: Projection.SwiftObject,
            implements: [COMImplements],
            agile: Bool = true,
            weakReferenceSource: Bool = true) {
        var implements = implements

        if agile {
            implements.append(COMImplements(
                id: IAgileObjectProjection.id,
                queryPointer: { identity in identity.unknown.addingRef() }))
        }

        if weakReferenceSource, let inspectable = implementation as? IInspectable {
            implements.append(COMImplements(id: IWeakReferenceSourceProjection.id, queryPointer: { identity in
                let export = COMExportedObject<IWeakReferenceSourceProjection>(
                    implementation: WeakReferenceSource(target: inspectable),
                    identity: identity)
                return export.unknown.addingRef()
            }))
        }

        super.init(
            implementation: implementation,
            implements: implements)
    }

    public override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        return id == IInspectableProjection.id
            ? identity.unknown.addingRef()
            : try super._queryInterfacePointer(id)
    }

    public final func getIids() throws -> [COMInterfaceID] { implements.map { $0.id } }
    open func getRuntimeClassName() throws -> String { try (implementation as! IInspectable).getRuntimeClassName() }
    open func getTrustLevel() throws -> TrustLevel { try (implementation as! IInspectable).getTrustLevel() }
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