import CWinRTCore
import COM

open class WinRTDelegate<Projection: COMTwoWayProjection>: COMImport<Projection> {
    public static func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        let comExport = COMExport<Projection>(implementation: object, queriableInterfaces: [ .init(Projection.self) ])
        return IUnknownPointer.addingRef(comExport.pointer)
    }
}