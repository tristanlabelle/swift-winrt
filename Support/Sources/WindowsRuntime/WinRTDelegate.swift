import CWinRTCore
import COM

open class WinRTDelegate<Projection: COMTwoWayProjection>: COMImport<Projection> {
    public static func toCOM(_ object: Projection.SwiftObject) throws -> Projection.COMPointer {
        let comExportedObject = COMExportedObject<Projection>(implementation: object, queriableInterfaces: [ .init(Projection.self) ])
        return IUnknownPointer.addingRef(comExportedObject.pointer)
    }
}