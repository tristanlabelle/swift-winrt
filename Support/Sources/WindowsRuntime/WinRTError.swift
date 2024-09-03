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
        self.init(hresult: hresult, errorInfo: message.map { MessageRestrictedErrorInfo(hresult: hresult, message: $0) })
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
        guard captureErrorInfo else { throw WinRTError(hresult: hresult) }

        let restrictedErrorInfo = try? Self.getRestrictedErrorInfo(matching: hresult)
        if let swiftErrorInfo = restrictedErrorInfo as? SwiftRestrictedErrorInfo, swiftErrorInfo.hresult == hresult {
            // This was originally a Swift error, throw it as such.
            throw swiftErrorInfo.error
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

        var message = message == nil ? nil : try? StringProjection.toABI(message!)
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

    private final class MessageRestrictedErrorInfo: COMPrimaryExport<IRestrictedErrorInfoProjection>,
            IRestrictedErrorInfoProtocol, IErrorInfoProtocol {
        public override class var implements: [COMImplements] { [
            .init(IErrorInfoProjection.self)
        ] }

        public let hresult: HResult
        public let message: String

        public init(hresult: HResult, message: String) {
            self.hresult = hresult
            self.message = message
        }

        // IErrorInfo
        public var guid: GUID { get throws { throw COMError.fail } }
        public var source: String? { get throws { throw COMError.fail } }
        public var description: String? { self.message }
        public var helpFile: String? { get throws { throw COMError.fail } }
        public var helpContext: UInt32 { get throws { throw COMError.fail } }

        // IRestrictedErrorInfo
        public func getErrorDetails(
                description: inout String?,
                error: inout HResult,
                restrictedDescription: inout String?,
                capabilitySid: inout String?) throws {
            description = self.message
            error = self.hresult
            restrictedDescription = self.message
            capabilitySid = nil
        }

        public var reference: String? { get throws { throw COMError.fail } }
    }
}