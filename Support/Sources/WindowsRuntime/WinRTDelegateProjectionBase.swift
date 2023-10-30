import CWinRTCore
import COM

open class WinRTDelegateProjectionBase<Projection: COMTwoWayProjection>: COMProjectionBase<Projection> {
    public static override func toABI(_ value: Projection.SwiftObject) throws -> Projection.COMPointer {
        let comExport = COMExport<Projection>(implementation: value, queriableInterfaces: [ .init(Projection.self) ])
        comExport.unknown.addRef()
        return comExport.pointer
    }
}