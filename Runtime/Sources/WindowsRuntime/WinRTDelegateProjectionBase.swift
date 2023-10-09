import CABI
import COM

open class WinRTDelegateProjectionBase<Projection: COMTwoWayProjection>: COMProjectionBase<Projection> {
    public static func toABI(_ value: Projection.SwiftValue) throws -> Projection.ABIValue {
        let comExport = COMExport<Projection>(implementation: value, queriableInterfaces: [ .init(Projection.self) ])
        comExport.unknown.addRef()
        return comExport.pointer
    }
}