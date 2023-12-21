import COM

/// Base for classes exported to WinRT.
open class WinRTExportedObject<Projection: WinRTTwoWayProjection>
        : COMExportedObject<Projection>, IInspectableProtocol {
    public override func _queryInterfacePointer(_ id: COMInterfaceID) throws -> IUnknownPointer {
        return id == IInspectableProjection.id
            ? identity.unknown.addingRef()
            : try super._queryInterfacePointer(id)
    }

    public final func getIids() throws -> [COMInterfaceID] { queriableInterfaces.map { $0.id } }
    open func getRuntimeClassName() throws -> String { try (implementation as! IInspectable).getRuntimeClassName() }
    open func getTrustLevel() throws -> TrustLevel { try (implementation as! IInspectable).getTrustLevel() }
}
