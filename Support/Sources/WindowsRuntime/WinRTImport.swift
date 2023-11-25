import CWinRTCore
import COM
import WinSDK
import struct Foundation.UUID

open class WinRTImport<Projection: WinRTProjection>: COMImport<Projection>, IInspectableProtocol {
    private var _inspectable: UnsafeMutablePointer<CWinRTCore.ABI_IInspectable> {
        comPointer.withMemoryRebound(to: CWinRTCore.ABI_IInspectable.self, capacity: 1) { $0 }
    }

    public func getIids() throws -> [Foundation.UUID] {
        var iids: COMArray<CWinRTCore.ABI_Guid> = .null
        try HResult.throwIfFailed(_inspectable.pointee.lpVtbl.pointee.GetIids(_inspectable, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return WinRTArrayProjection<GUIDProjection>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        // Can't use _getter because comPointer is not of type UnsafeMutablePointer<CWinRTCore.ABI_IInspectable>
        var runtimeClassName: CWinRTCore.ABI_HString?
        try HResult.throwIfFailed(_inspectable.pointee.lpVtbl.pointee.GetRuntimeClassName(_inspectable, &runtimeClassName))
        return HStringProjection.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        // Can't use _getter because comPointer is not of type UnsafeMutablePointer<CWinRTCore.ABI_IInspectable>
        var trustLevel: CWinRTCore.ABI_TrustLevel = 0
        try HResult.throwIfFailed(_inspectable.pointee.lpVtbl.pointee.GetTrustLevel(_inspectable, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}