import COM
import CWinRTCore
import struct Foundation.UUID

/// Marker protocol for COM interface structs deriving from IInspectable.
/// This protocol shouldn't be used for dynamic casting because conformances will be @retroactive.
public protocol COMIInspectableStruct {}

extension CWinRTCore.SWRT_IInspectable: /* @retroactive */ COMIInspectableStruct {}

extension COMInterop where Interface: COMIInspectableStruct {
    private var inspectable: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>{
        this.withMemoryRebound(to: CWinRTCore.SWRT_IInspectable.self, capacity: 1) { $0 }
    }

    public func getIids() throws -> [Foundation.UUID] {
        var iids: COMArray<CWinRTCore.SWRT_Guid> = .null
        try WinRTError.throwIfFailed(inspectable.pointee.lpVtbl.pointee.GetIids(inspectable, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return WinRTArrayProjection<GUIDProjection>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        var runtimeClassName: CWinRTCore.SWRT_HString?
        try WinRTError.throwIfFailed(inspectable.pointee.lpVtbl.pointee.GetRuntimeClassName(inspectable, &runtimeClassName))
        return HStringProjection.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        var trustLevel: CWinRTCore.SWRT_TrustLevel = 0
        try WinRTError.throwIfFailed(inspectable.pointee.lpVtbl.pointee.GetTrustLevel(inspectable, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}