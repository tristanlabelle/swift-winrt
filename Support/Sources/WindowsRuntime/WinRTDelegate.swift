import CWinRTCore
import COM

open class WinRTDelegate<Projection: COMTwoWayProjection>: COMImport<Projection> {
    public static func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        COMWrappingExport<Projection>(implementation: object).toCOM()
    }
}