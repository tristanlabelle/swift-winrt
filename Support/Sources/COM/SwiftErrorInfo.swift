// Wraps a Swift Error object into an `IErrorInfo` to preserve it across WinRT boundaries.
open class SwiftErrorInfo: COMPrimaryExport<IErrorInfoProjection>, IErrorInfoProtocol {
    public let error: Error

    public init(error: Error) {
        self.error = error
    }

    open func toABI(setErrorInfo: Bool = true) -> HResult.Value {
        if setErrorInfo { try? COMError.setErrorInfo(self) }
        return hresult.value
    }

    public var hresult: HResult { (self.error as? ErrorWithHResult)?.hresult ?? HResult.fail }
    public var message: String { String(describing: error) }

    // IErrorInfo
    public var guid: GUID { get throws { throw COMError.fail } }
    public var source: String? { get throws { throw COMError.fail } }
    public var description: String? { self.message }
    public var helpFile: String? { get throws { throw COMError.fail } }
    public var helpContext: UInt32 { get throws { throw COMError.fail } }
}