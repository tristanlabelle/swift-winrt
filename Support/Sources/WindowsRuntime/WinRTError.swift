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
        if let swiftErrorInfo = error.errorInfo as? SwiftRestrictedErrorInfo, swiftErrorInfo.hresult == hresult {
            // This was originally a Swift error, throw it as such.
            throw swiftErrorInfo.error
        }
        throw error
    }

    public static func catchAndOriginate(_ body: () throws -> Void) -> WindowsRuntime_ABI.SWRT_HResult {
        do {
            try body()
            return HResult.ok.value
        }
        catch let error {
            let errorInfo = SwiftRestrictedErrorInfo(error: error)
            let hresult = errorInfo.hresult.value
            var message = (try? StringProjection.toABI(errorInfo.message)) ?? nil
            defer { StringProjection.release(&message) }
            var iunknown = try? IUnknownProjection.toABI(errorInfo)
            defer { IUnknownProjection.release(&iunknown) }
            WindowsRuntime_ABI.SWRT_RoOriginateLanguageException(hresult, message, iunknown)
            return hresult
        }
    }

    public static func clear() {
        WindowsRuntime_ABI.SWRT_RoClearError()
    }

    public static func captureErrorContext(hresult: HResult) throws {
        try HResult.throwIfFailed(SWRT_RoCaptureErrorContext(hresult.value))
    }

    public static func failFastWithErrorContext(hresult: HResult) throws {
        SWRT_RoFailFastWithErrorContext(hresult.value)
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