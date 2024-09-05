import COM_ABI

/// Protocol for errors with an associated HResult value.
public protocol ErrorWithHResult: Error {
    var hresult: HResult { get }
}

public protocol COMErrorProtocol: ErrorWithHResult {
    /// Gets the error info for
    var errorInfo: IErrorInfo? { get }

    /// Converts this COM error to its ABI representation, including thread-local COM error information.
    func toABI(setErrorInfo: Bool) -> HResult.Value
}

extension COMErrorProtocol {
    /// Converts this COM error to its ABI representation, including thread-local COM error information.
    public func toABI() -> HResult.Value { toABI(setErrorInfo: true) }
}

/// Captures a failure from a COM API invocation (HRESULT + optional IErrorInfo).
public struct COMError: COMErrorProtocol, CustomStringConvertible {
    public static let fail = Self(hresult: HResult.fail)
    public static let illegalMethodCall = Self(hresult: HResult.illegalMethodCall)
    public static let invalidArg = Self(hresult: HResult.invalidArg)
    public static let notImpl = Self(hresult: HResult.notImpl)
    public static let noInterface = Self(hresult: HResult.noInterface)
    public static let pointer = Self(hresult: HResult.pointer)
    public static let outOfMemory = Self(hresult: HResult.outOfMemory)

    public let hresult: HResult // Invariant: isFailure
    public let errorInfo: IErrorInfo?

    public init(hresult: HResult, errorInfo: IErrorInfo? = nil) {
        assert(hresult.isFailure)
        self.hresult = hresult
        self.errorInfo = errorInfo
    }

    public init(hresult: HResult, description: String?) {
        self.init(hresult: hresult, errorInfo: description.flatMap { try? Self.createErrorInfo(description: $0) })
    }

    public var description: String {
        if let errorInfo, let description = try? errorInfo.description { return description }
        return hresult.description
    }

    public func toABI(setErrorInfo: Bool = true) -> HResult.Value {
        if setErrorInfo { try? Self.setErrorInfo(errorInfo) }
        return hresult.value
    }

    /// Throws any failure HRESULTs as COMErrors, optionally capturing the COM thread error info. 
    @discardableResult
    public static func fromABI(captureErrorInfo: Bool = true, _ hresult: HResult.Value) throws -> HResult {
        let hresult = HResult(hresult)
        guard hresult.isFailure else { return hresult }
        guard captureErrorInfo else { throw COMError(hresult: hresult) }

        let errorInfo = try? Self.getErrorInfo()
        if let swiftErrorInfo = errorInfo as? SwiftErrorInfo, swiftErrorInfo.hresult == hresult {
            // This was originally a Swift error, throw it as such.
            throw swiftErrorInfo.error
        }

        throw COMError(hresult: hresult, errorInfo: errorInfo)
    }

    /// Catches any thrown errors from a provided closure, converting it to an HRESULT and optionally setting the COM thread error info state.
    public static func toABI(setErrorInfo: Bool = true, _ body: () throws -> Void) -> HResult.Value {
        do { try body() }
        catch { return toABI(error: error, setErrorInfo: setErrorInfo) }
        return HResult.ok.value
    }

    public static func toABI(error: Error, setErrorInfo: Bool = true) -> HResult.Value {
        // If the error already came from COM/WinRT, propagate it
        if let comError = error as? any COMErrorProtocol { return comError.toABI(setErrorInfo: setErrorInfo) }

        // Otherwise, create a new error info and set it
        return SwiftErrorInfo(error: error).toABI(setErrorInfo: setErrorInfo)
    }

    public static func toABI(hresult: HResult, description: String? = nil) -> HResult.Value {
        guard hresult.isFailure else { return hresult.value }
        return Self(hresult: hresult, description: description).toABI()
    }

    public static func getErrorInfo() throws -> IErrorInfo? {
        var errorInfo: UnsafeMutablePointer<SWRT_IErrorInfo>?
        defer { IErrorInfoProjection.release(&errorInfo) }
        try fromABI(captureErrorInfo: false, COM_ABI.SWRT_GetErrorInfo(/* dwReserved: */ 0, &errorInfo))
        return IErrorInfoProjection.toSwift(consuming: &errorInfo)
    }

    public static func setErrorInfo(_ errorInfo: IErrorInfo?) throws {
        var errorInfo = try IErrorInfoProjection.toABI(errorInfo)
        defer { IErrorInfoProjection.release(&errorInfo) }
        try fromABI(captureErrorInfo: false, COM_ABI.SWRT_SetErrorInfo(/* dwReserved: */ 0, errorInfo))
    }
}