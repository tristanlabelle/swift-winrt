import COM

open class WinRTExport<Projection: WinRTTwoWayProjection>
        : COMExport<Projection>, IInspectableProtocol {
    public override func _queryInterfacePointer(_ iid: IID) throws -> IUnknownPointer {
        return iid == IInspectableProjection.iid
            ? identity.unknown.addingRef()
            : try super._queryInterfacePointer(iid)
    }

    public final func getIids() throws -> [IID] { queriableInterfaces.map { $0.iid } }
    open func getRuntimeClassName() throws -> String { try (implementation as! IInspectable).getRuntimeClassName() }
    open func getTrustLevel() throws -> TrustLevel { try (implementation as! IInspectable).getTrustLevel() }
}
