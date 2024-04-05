import COM
import WindowsRuntime_ABI

public struct WinRTError: COMError, CustomStringConvertible {
    public let hresult: HResult
    public let errorInfo: IRestrictedErrorInfo?

    public init?(hresult: HResult, captureErrorInfo: Bool) {
        if hresult.isSuccess { return nil }
        self.hresult = hresult
        self.errorInfo = captureErrorInfo ? try? Self.getRestrictedErrorInfo(matching: hresult) : nil
    }

    public var description: String {
        let details = (try? errorInfo?.details) ?? RestrictedErrorInfoDetails()
        // RestrictedDescription contains the value reported in RoOriginateError
        return details.restrictedDescription ?? details.description ?? hresult.description
    }

    public static func throwIfFailed(_ hresult: WindowsRuntime_ABI.SWRT_HResult) throws {
        let hresult = HResultProjection.toSwift(hresult)
        guard let error = WinRTError(hresult: hresult, captureErrorInfo: true) else { return }
        throw error
    }

    public static func catchAndOriginate(_ body: () throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
        do {
            try body()
            return HResult.ok.value
        }
        catch let error {
            let hresult = (error as? COMError)?.hresult ?? HResult.fail
            var message = (try? PrimitiveProjection.String.toABI(error.localizedDescription)) ?? nil
            defer { PrimitiveProjection.String.release(&message) }
            WindowsRuntime_ABI.SWRT_RoOriginateError(hresult.value, message)
            return hresult.value
        }
    }

    public static func getRestrictedErrorInfo() throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }

        // Don't throw a WinRTError, that would be recursive
        let hresult = WindowsRuntime_ABI.SWRT_GetRestrictedErrorInfo(&restrictedErrorInfo)
        if let error = WinRTError(hresult: HResult(hresult), captureErrorInfo: false) { throw error }

        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }

    public static func getRestrictedErrorInfo(matching expectedHResult: HResult) throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }

        let hresult = WindowsRuntime_ABI.SWRT_RoGetMatchingRestrictedErrorInfo(expectedHResult.value, &restrictedErrorInfo)
        if let error = WinRTError(hresult: HResult(hresult), captureErrorInfo: false) { throw error }

        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }
}