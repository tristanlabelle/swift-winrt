import CWinRTCore
import COM
import WinSDK

/// Protocol for strongly-typed two-way WinRT interface/delegate/runtimeclass projections into and from Swift.
public protocol WinRTTwoWayProjection: WinRTProjection, COMTwoWayProjection {}

/// Helpers for implementing virtual tables
extension WinRTTwoWayProjection {
    public static func _getIids(
            _ this: COMPointer?,
            _ count: UnsafeMutablePointer<UInt32>?,
            _ iids: UnsafeMutablePointer<UnsafeMutablePointer<CWinRTCore.SWRT_Guid>?>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let count, let iids else { return HResult.invalidArg.value }
        count.pointee = 0
        iids.pointee = nil
        let object = _getImplementation(this) as! IInspectable
        return HResult.catchValue {
            let idsArray = try object.getIids()
            let comArray = try WinRTArrayProjection<GUIDProjection>.toABI(idsArray)
            count.pointee = comArray.count
            iids.pointee = comArray.pointer
        }
    }

    public static func _getRuntimeClassName(
            _ this: COMPointer?,
            _ className: UnsafeMutablePointer<CWinRTCore.SWRT_HString?>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let className else { return HResult.invalidArg.value }
        className.pointee = nil
        let object = _getImplementation(this) as! IInspectable
        return HResult.catchValue {
            className.pointee = try HStringProjection.toABI(object.getRuntimeClassName())
        }
    }

    public static func _getTrustLevel(
            _ this: COMPointer?,
            _ trustLevel: UnsafeMutablePointer<CWinRTCore.SWRT_TrustLevel>?) -> CWinRTCore.SWRT_HResult {
        guard let this, let trustLevel else { return HResult.invalidArg.value }
        let object = _getImplementation(this) as! IInspectable
        return HResult.catchValue {
            trustLevel.pointee = try TrustLevel.toABI(object.getTrustLevel())
        }
    }
}