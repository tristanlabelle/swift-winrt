import COM
import CWinRTCore
import struct Foundation.UUID

/// Marker protocol for COM interface structs deriving from IInspectable.
/// This protocol shouldn't be used for dynamic casting because conformances will be @retroactive.
public protocol COMIInspectableStruct {}

extension CWinRTCore.SWRT_IInspectable: /* @retroactive */ COMIInspectableStruct {}

extension COMInterop where Interface: COMIInspectableStruct {
    private var _inspectablePointer: UnsafeMutablePointer<CWinRTCore.SWRT_IInspectable>{
        _pointer.withMemoryRebound(to: CWinRTCore.SWRT_IInspectable.self, capacity: 1) { $0 }
    }

    public func getIids() throws -> [Foundation.UUID] {
        var iids: COMArray<CWinRTCore.SWRT_Guid> = .null
        try WinRTError.throwIfFailed(_inspectablePointer.pointee.lpVtbl.pointee.GetIids(_inspectablePointer, &iids.count, &iids.pointer))
        defer { iids.deallocate() }
        return WinRTArrayProjection<GUIDProjection>.toSwift(consuming: &iids)
    }

    public func getRuntimeClassName() throws -> String {
        var runtimeClassName: CWinRTCore.SWRT_HString?
        try WinRTError.throwIfFailed(_inspectablePointer.pointee.lpVtbl.pointee.GetRuntimeClassName(_inspectablePointer, &runtimeClassName))
        return HStringProjection.toSwift(consuming: &runtimeClassName)
    }

    public func getTrustLevel() throws -> TrustLevel {
        var trustLevel: CWinRTCore.SWRT_TrustLevel = 0
        try WinRTError.throwIfFailed(_inspectablePointer.pointee.lpVtbl.pointee.GetTrustLevel(_inspectablePointer, &trustLevel))
        return TrustLevel.toSwift(trustLevel)
    }
}