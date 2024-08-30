import COM

// Wraps a Swift Error object into an `IRestrictedErrorInfo` to preserve it across WinRT boundaries.
internal final class SwiftRestrictedErrorInfo: COMPrimaryExport<IRestrictedErrorInfoProjection>,
        IRestrictedErrorInfoProtocol, IErrorInfoProtocol {
    override class var implements: [COMImplements] { [
        .init(IErrorInfoProjection.self)
    ] }

    public let error: any Error

    public init(error: any Error) {
        self.error = error
    }

    public var hresult: HResult { (self.error as? COMError)?.hresult ?? HResult.fail }
    public var message: String { String(describing: error) }

    // IErrorInfo
    public var guid: GUID { get throws { throw HResult.Error.fail } }
    public var source: String? { get throws { throw HResult.Error.fail } }
    public var description: String? { self.message }
    public var helpFile: String? { get throws { throw HResult.Error.fail } }
    public var helpContext: UInt32 { get throws { throw HResult.Error.fail } }

    // IRestrictedErrorInfo
    public func getErrorDetails(
            description: inout String?,
            error: inout HResult,
            restrictedDescription: inout String?,
            capabilitySid: inout String?) throws {
        description = self.description
        error = self.hresult
        restrictedDescription = description
        capabilitySid = nil
    }

    public var reference: String? { get throws { throw HResult.Error.fail } }
}