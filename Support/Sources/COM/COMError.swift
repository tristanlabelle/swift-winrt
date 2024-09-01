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
    public static let fail = Self(failed: HResult.fail, captureErrorInfo: false)
    public static let illegalMethodCall = Self(failed: HResult.illegalMethodCall, captureErrorInfo: false)
    public static let invalidArg = Self(failed: HResult.invalidArg, captureErrorInfo: false)
    public static let notImpl = Self(failed: HResult.notImpl, captureErrorInfo: false)
    public static let noInterface = Self(failed: HResult.noInterface, captureErrorInfo: false)
    public static let pointer = Self(failed: HResult.pointer, captureErrorInfo: false)
    public static let outOfMemory = Self(failed: HResult.outOfMemory, captureErrorInfo: false)

    public let hresult: HResult // Invariant: isFailure
    public let errorInfo: IErrorInfo?

    private init(failed hresult: HResult, captureErrorInfo: Bool) {
        assert(hresult.isFailure)
        self.hresult = hresult
        self.errorInfo = try? Self.getErrorInfo() 
    }

    public init?(hresult: HResult, errorInfo: IErrorInfo?) {
        guard hresult.isFailure else { return nil }
        self.hresult = hresult
        self.errorInfo = errorInfo
    }

    public init?(hresult: HResult, captureErrorInfo: Bool) {
        guard hresult.isFailure else { return nil }
        self.init(failed: hresult, captureErrorInfo: captureErrorInfo)
    }

    public init?(hresult: HResult.Value, captureErrorInfo: Bool) {
        self.init(hresult: HResult(hresult), captureErrorInfo: captureErrorInfo)
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
        if let comError = COMError(hresult: hresult, captureErrorInfo: captureErrorInfo) { throw comError }
        return hresult
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
        try? Self.setErrorInfo(description.map { DescriptiveErrorInfo(description: $0) })
        return hresult.value
    }

    public static func getErrorInfo() throws -> IErrorInfo? {
        var errorInfo: UnsafeMutablePointer<SWRT_IErrorInfo>?
        defer { IErrorInfoProjection.release(&errorInfo) }

        let getErrorInfoHResult = COM_ABI.SWRT_GetErrorInfo(/* dwReserved: */ 0, &errorInfo)

        // GetErrorInfo failed, so don't call it again
        if let error = COMError(hresult: getErrorInfoHResult, captureErrorInfo: false) { throw error }

        return IErrorInfoProjection.toSwift(consuming: &errorInfo)
    }

    public static func setErrorInfo(_ errorInfo: IErrorInfo?) throws {
        var errorInfo = try IErrorInfoProjection.toABI(errorInfo)
        defer { IErrorInfoProjection.release(&errorInfo) }

        let setErrorInfoHResult = COM_ABI.SWRT_SetErrorInfo(/* dwReserved: */ 0, errorInfo)

        // SetErrorInfo failed, so don't call GetErrorInfo
        if let error = COMError(hresult: setErrorInfoHResult, captureErrorInfo: false) { throw error }
    }

    private final class DescriptiveErrorInfo: COMPrimaryExport<IErrorInfoProjection>, IErrorInfoProtocol {
        private let _description: String
        public init(description: String) { self._description = description }

        // IErrorInfo
        public var guid: GUID { get throws { throw COMError.fail } }
        public var source: String? { get throws { throw COMError.fail } }
        public var description: String? { self._description }
        public var helpFile: String? { get throws { throw COMError.fail } }
        public var helpContext: UInt32 { get throws { throw COMError.fail } }
    }
}