import COM

/// Base for classes exported to WinRT.
open class WinRTExportedObject<Projection: WinRTTwoWayProjection>
        : COMExportedObject<Projection>, IInspectableProtocol {
    public init(
            implementation: Projection.SwiftObject,
            queriableInterfaces: [COMExportInterface],
            agile: Bool = true,
            weakReferenceSource: Bool = true) {
        var fullQueriableInterfaces = queriableInterfaces

        if agile {
            fullQueriableInterfaces.append(COMExportInterface(
                id: IAgileObjectProjection.id,
                queryPointer: { identity in identity.unknown.addingRef() }))
        }

        if weakReferenceSource, let inspectable = implementation as? IInspectable {
            fullQueriableInterfaces.append(COMExportInterface(id: IWeakReferenceSourceProjection.id, queryPointer: { identity in
                let export = COMExportedObject<IWeakReferenceSourceProjection>(
                    implementation: WeakReferenceSource(target: inspectable),
                    identity: identity)
                return export.unknown.addingRef()
            }))
        }

        super.init(
            implementation: implementation,
            queriableInterfaces: fullQueriableInterfaces)
    }

    public override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        return id == IInspectableProjection.id
            ? identity.unknown.addingRef()
            : try super._queryInterfacePointer(id)
    }

    public final func getIids() throws -> [COMInterfaceID] { queriableInterfaces.map { $0.id } }
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