import COM

open class WinRTExport<Projection: WinRTTwoWayProjection>
        : COMExport<Projection>, IInspectableProtocol {
    open class var _runtimeClassName: String { String(describing: Self.self) }
    open class var _trustLevel: TrustLevel { .base }

    public override func _createCOMObject() -> COMExportedObject<Projection> {
        WinRTExportedObject<Projection>(
            implementation: self as! Projection.SwiftObject,
            queriableInterfaces: Self.queriableInterfaces)
    }
    
    public final func getIids() throws -> [COMInterfaceID] { Self.queriableInterfaces.map { $0.id } }
    public final func getRuntimeClassName() throws -> String { Self._runtimeClassName }
    public final func getTrustLevel() throws -> TrustLevel { Self._trustLevel }
}