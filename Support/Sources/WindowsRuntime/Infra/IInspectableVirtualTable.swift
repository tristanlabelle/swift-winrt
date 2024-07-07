import COM
import WindowsRuntime_ABI

public enum IInspectableVirtualTable {
    public static func GetIids<ABIStruct>(
            _ this: UnsafeMutablePointer<ABIStruct>?,
            _ count: UnsafeMutablePointer<UInt32>?,
            _ iids: UnsafeMutablePointer<UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_Guid>?>?) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this, let count, let iids else { return HResult.invalidArg.value }
        count.pointee = 0
        iids.pointee = nil
        let object = COMEmbedding.getEmbedderObjectOrCrash(this) as! IInspectable
        return HResult.catchValue {
            let idsArray = try object.getIids()
            let comArray = try ArrayProjection<GUIDProjection>.toABI(idsArray)
            count.pointee = comArray.count
            iids.pointee = comArray.pointer
        }
    }

    public static func GetRuntimeClassName<ABIStruct>(
            _ this: UnsafeMutablePointer<ABIStruct>?,
            _ className: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_HString?>?) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this, let className else { return HResult.invalidArg.value }
        className.pointee = nil
        let object = COMEmbedding.getEmbedderObjectOrCrash(this) as! IInspectable
        return HResult.catchValue {
            className.pointee = try PrimitiveProjection.String.toABI(object.getRuntimeClassName())
        }
    }

    public static func GetTrustLevel<ABIStruct>(
            _ this: UnsafeMutablePointer<ABIStruct>?,
            _ trustLevel: UnsafeMutablePointer<WindowsRuntime_ABI.SWRT_TrustLevel>?) -> WindowsRuntime_ABI.SWRT_HResult {
        guard let this, let trustLevel else { return HResult.invalidArg.value }
        let object = COMEmbedding.getEmbedderObjectOrCrash(this) as! IInspectable
        return HResult.catchValue {
            trustLevel.pointee = try TrustLevel.toABI(object.getTrustLevel())
        }
    }
}