import COM
import CWinRTCore
import struct Foundation.UUID

/// Identifies COM interface structs as deriving from IInspectable.
/// Do not use for dynamic casting because conformances will be @retroactive.
public protocol COMIInspectableStruct: COMIUnknownStruct {
}

extension COMInterop where Interface: /* @retroactive */ COMIInspectableStruct {
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