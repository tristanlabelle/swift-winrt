import COM
import WindowsRuntime_ABI

/// Captures a failure from a WinRT API invocation (HRESULT + optional IRestrictedErrorInfo).
/// This error object only differs from COMError in that it relies on `IRestrictedErrorInfo` for the message.
/// Also exposes WinRT error APIs as static members.
public struct WinRTError: COMErrorProtocol, CustomStringConvertible {
    public let hresult: HResult
    public let restrictedErrorInfo: IRestrictedErrorInfo?

    public init?(hresult: HResult, captureErrorInfo: Bool) {
        guard hresult.isFailure else { return nil }
        self.hresult = hresult
        self.restrictedErrorInfo = captureErrorInfo ? try? Self.getRestrictedErrorInfo(matching: hresult) : nil
    }

    public init?(hresult: HResult.Value, captureErrorInfo: Bool) {
        self.init(hresult: HResult(hresult), captureErrorInfo: captureErrorInfo)
    }

    public var errorInfo: IErrorInfo? {
        try? restrictedErrorInfo?.queryInterface(IErrorInfoProjection.self)
    }

    public var description: String {
        let details = (try? restrictedErrorInfo?.details) ?? RestrictedErrorInfoDetails()
        // RestrictedDescription contains the value reported in RoOriginateError
        return details.restrictedDescription ?? details.description ?? hresult.description
    }

    public func toABI(setErrorInfo: Bool = true) -> HResult.Value {
        if setErrorInfo { try? Self.setRestrictedErrorInfo(restrictedErrorInfo) }
        return hresult.value
    }

    /// Throws any failure HRESULTs as WinRTErrors, optionally capturing the WinRT thread error info. 
    @discardableResult
    public static func fromABI(_ hresult: WindowsRuntime_ABI.SWRT_HResult) throws -> HResult {
        let hresult = HResult(hresult)
        guard let error = WinRTError(hresult: hresult, captureErrorInfo: true) else { return hresult }
        if let swiftErrorInfo = error.restrictedErrorInfo as? SwiftRestrictedErrorInfo, swiftErrorInfo.hresult == hresult {
            // This was originally a Swift error, throw it as such.
            throw swiftErrorInfo.error
        }
        throw error
    }

    /// Catches any thrown errors from a provided closure, converting it to an HRESULT and setting the WinRT error info state.
    public static func toABI(originate: Bool = true, captureContext: Bool = true, _ body: () throws -> Void) -> HResult.Value {
        do { try body() }
        catch { return toABI(error: error, originate: originate, captureContext: captureContext) }
        return HResult.ok.value
    }

    public static func toABI(error: Error, originate: Bool = true, captureContext: Bool = true) -> HResult.Value {
        // If the error already came from COM/WinRT, propagate it
        if let comError = error as? any COMErrorProtocol { return comError.toABI() }

        // Otherwise, originate a new error
        let restrictedErrorInfo = SwiftRestrictedErrorInfo(error: error)
        if originate { restrictedErrorInfo.originate(captureContext: captureContext) }
        return restrictedErrorInfo.hresult.value
    }

    public static func toABI(hresult: HResult, message: String? = nil, captureContext: Bool = true) -> HResult.Value {
        guard hresult.isFailure else { return hresult.value }
        Self.originate(hresult: hresult, message: message)
        if captureContext { try? Self.captureContext(hresult: hresult) }
        return hresult.value
    }

    @discardableResult
    public static func originate(hresult: HResult, message: String?) -> Bool {
        var message = message == nil ? nil : try? StringProjection.toABI(message!)
        defer { StringProjection.release(&message) }
        return WindowsRuntime_ABI.SWRT_RoOriginateError(hresult.value, message)
    }

    @discardableResult
    public static func originate(hresult: HResult, message: String?, restrictedErrorInfo: IRestrictedErrorInfo?) -> Bool {
        guard let restrictedErrorInfo else { return originate(hresult: hresult, message: message) }

        var message = message == nil ? nil : try? PrimitiveProjection.String.toABI(message!)
        defer { StringProjection.release(&message) }
        var iunknown = try? IUnknownProjection.toABI(restrictedErrorInfo)
        defer { IUnknownProjection.release(&iunknown) }
        return WindowsRuntime_ABI.SWRT_RoOriginateLanguageException(hresult.value, message, iunknown)
    }

    public static func clear() {
        WindowsRuntime_ABI.SWRT_RoClearError()
    }

    public static func captureContext(hresult: HResult) throws {
        try COMError.fromABI(SWRT_RoCaptureErrorContext(hresult.value))
    }

    public static func failFastWithContext(hresult: HResult) throws {
        SWRT_RoFailFastWithErrorContext(hresult.value)
    }

    public static func getRestrictedErrorInfo() throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }

        let getRestrictedErrorInfoHResult = WindowsRuntime_ABI.SWRT_GetRestrictedErrorInfo(&restrictedErrorInfo)
        // If GetRestrictedErrorInfo failed, don't call GetRestrictedErrorInfo
        if let error = WinRTError(hresult: getRestrictedErrorInfoHResult, captureErrorInfo: false) { throw error }

        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }

    public static func getRestrictedErrorInfo(matching expectedHResult: HResult) throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }

        let getRestrictedErrorInfoHResult = WindowsRuntime_ABI.SWRT_RoGetMatchingRestrictedErrorInfo(expectedHResult.value, &restrictedErrorInfo)
        // If RoGetMatchingRestrictedErrorInfo failed, don't call GetRestrictedErrorInfo
        if let error = WinRTError(hresult: getRestrictedErrorInfoHResult, captureErrorInfo: false) { throw error }

        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }

    public static func setRestrictedErrorInfo(_ value: IRestrictedErrorInfo?) throws {
        var abiValue = try IRestrictedErrorInfoProjection.toABI(value)
        defer { IRestrictedErrorInfoProjection.release(&abiValue) }

        let setRestrictedErrorInfoHResult = WindowsRuntime_ABI.SWRT_SetRestrictedErrorInfo(abiValue)
        // If SetRestrictedErrorInfo failed, don't call GetRestrictedErrorInfo
        if let error = WinRTError(hresult: setRestrictedErrorInfoHResult, captureErrorInfo: false) { throw error }
    }
}