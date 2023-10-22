import CWinRTCore

public enum HResultProjection: ABIInertProjection {
    public typealias SwiftValue = HResult
    public typealias ABIValue = CWinRTCore.HRESULT

    public static var abiDefaultValue: ABIValue { CWinRTCore.S_OK }
    public static func toSwift(_ value: CWinRTCore.HRESULT) -> SwiftValue { HResult(value) }
    public static func toABI(_ value: HResult) -> CWinRTCore.HRESULT { value.value }
}