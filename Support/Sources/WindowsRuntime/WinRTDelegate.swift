import CWinRTCore
import COM

open class WinRTDelegate<Projection: COMTwoWayProjection>: COMImport<Projection> {
    public static func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        let comExport = COMWrappingExport<Projection>(implementation: object)
        return comExport.unknownPointer.addingRef().withMemoryRebound(to: Projection.COMInterface.self, capacity: 1) { $0 }
    }
}