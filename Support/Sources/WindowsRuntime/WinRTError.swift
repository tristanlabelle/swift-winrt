import COM
import WindowsRuntime_ABI

/// Captures a failure from a WinRT API invocation (HRESULT + optional IRestrictedErrorInfo).
/// This error object only differs from COMError in that it relies on `IRestrictedErrorInfo` for the message.
/// Also exposes WinRT error APIs as static members.
public struct WinRTError: COMErrorProtocol, CustomStringConvertible {
    public let hresult: HResult
    public let restrictedErrorInfo: IRestrictedErrorInfo?

    public init(hresult: HResult, errorInfo: IRestrictedErrorInfo? = nil) {
        assert(hresult.isFailure)
        self.hresult = hresult
        self.restrictedErrorInfo = errorInfo
    }

    public init(hresult: HResult, message: String?) {
        let errorInfo = message.flatMap { try? Self.createRestrictedErrorInfo(hresult: hresult, message: $0) }
        self.init(hresult: hresult, errorInfo: errorInfo)
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
    public static func fromABI(captureErrorInfo: Bool = true, _ hresult: WindowsRuntime_ABI.SWRT_HResult) throws -> HResult {
        let hresult = HResult(hresult)
        guard hresult.isFailure else { return hresult }

        // Check for an associated IRestrictedErrorInfo
        guard captureErrorInfo, let restrictedErrorInfo = try? Self.getRestrictedErrorInfo(matching: hresult) else {
            throw WinRTError(hresult: hresult)
        }

        // Ensure we didn't get a stale IRestrictedErrorInfo
        var description: String? = nil
        var error: HResult = .ok
        var restrictedDescription: String? = nil
        var capabilitySid: String? = nil
        try? restrictedErrorInfo.getErrorDetails(
            description: &description, error: &error,
            restrictedDescription: &restrictedDescription, capabilitySid: &capabilitySid)
        guard error == hresult else { throw WinRTError(hresult: hresult) }

        // Append to the propagation context, if available.
        // See https://learn.microsoft.com/en-us/windows/win32/api/restrictederrorinfo/nf-restrictederrorinfo-ilanguageexceptionerrorinfo2-capturepropagationcontext
        if let languageExceptionErrorInfo = try? restrictedErrorInfo.queryInterface(ILanguageExceptionErrorInfoProjection.self) {
            let languageException = try? languageExceptionErrorInfo.languageException as? LanguageException

            if let languageExceptionErrorInfo2 = try? languageExceptionErrorInfo.queryInterface(ILanguageExceptionErrorInfo2Projection.self) {
                try languageExceptionErrorInfo2.capturePropagationContext(nil) // No new language exception to provide
            }

            if let languageException {
                throw languageException.error
            }
        }

        throw WinRTError(hresult: hresult, errorInfo: restrictedErrorInfo)
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
        let hresult = (error as? ErrorWithHResult)?.hresult ?? HResult.fail
        if originate && Self.originate(hresult: hresult, message: String(describing: error), languageException: LanguageException(error: error)) {
            if captureContext { try? Self.captureContext(hresult: hresult) }
        }

        return hresult.value
    }

    public static func toABI(hresult: HResult, message: String? = nil, captureContext: Bool = true) -> HResult.Value {
        guard hresult.isFailure else { return hresult.value }
        if Self.originate(hresult: hresult, message: message) {
            if captureContext { try? Self.captureContext(hresult: hresult) }
        }
        return hresult.value
    }

    @discardableResult
    public static func originate(hresult: HResult, message: String?) -> Bool {
        var message = message == nil ? nil : try? StringProjection.toABI(message!)
        defer { StringProjection.release(&message) }
        return WindowsRuntime_ABI.SWRT_RoOriginateError(hresult.value, message)
    }

    @discardableResult
    public static func originate(hresult: HResult, message: String?, languageException: IUnknown?) -> Bool {
        guard let languageException else { return originate(hresult: hresult, message: message) }

        var message = message == nil ? nil : try? StringProjection.toABI(message!)
        defer { StringProjection.release(&message) }
        var iunknown = try? IUnknownProjection.toABI(languageException)
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

    public static func createRestrictedErrorInfo(hresult: HResult, message: String?, languageException: IUnknown? = nil) throws -> IRestrictedErrorInfo {
        // From the SetRestrictedErrorInfo docs at https://learn.microsoft.com/en-us/windows/win32/api/roerrorapi/nf-roerrorapi-setrestrictederrorinfo:
        // > The call fails if IRestrictedErrorInfo isn't the system implementation.
        // > To create an IRestrictedErrorInfo object, call the OriginateError, TransformError, or RoCaptureErrorContext functions.
        // But RoOriginateError overwrites the current thread error info object,
        // so we need to manually save and restore it around the call to RoOriginateError.
        let previousErrorInfo = try? COMError.getErrorInfo()
        defer { try? COMError.setErrorInfo(previousErrorInfo) }
        return try NullResult.unwrap(Self.originate(hresult: hresult, message: message) ? try? Self.getRestrictedErrorInfo() : nil)
    }

    public static func getRestrictedErrorInfo() throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }
        try fromABI(captureErrorInfo: false, WindowsRuntime_ABI.SWRT_GetRestrictedErrorInfo(&restrictedErrorInfo))
        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }

    public static func getRestrictedErrorInfo(matching expectedHResult: HResult) throws -> IRestrictedErrorInfo? {
        var restrictedErrorInfo: UnsafeMutablePointer<SWRT_IRestrictedErrorInfo>?
        defer { IRestrictedErrorInfoProjection.release(&restrictedErrorInfo) }
        try fromABI(captureErrorInfo: false, WindowsRuntime_ABI.SWRT_RoGetMatchingRestrictedErrorInfo(expectedHResult.value, &restrictedErrorInfo))
        return IRestrictedErrorInfoProjection.toSwift(consuming: &restrictedErrorInfo)
    }

    public static func setRestrictedErrorInfo(_ value: IRestrictedErrorInfo?) throws {
        var abiValue = try IRestrictedErrorInfoProjection.toABI(value)
        defer { IRestrictedErrorInfoProjection.release(&abiValue) }
        try fromABI(captureErrorInfo: false, WindowsRuntime_ABI.SWRT_SetRestrictedErrorInfo(abiValue))
    }
}