import COM

// Wraps a Swift Error object into an `IRestrictedErrorInfo` to preserve it across WinRT boundaries.
public class SwiftRestrictedErrorInfo: SwiftErrorInfo, IRestrictedErrorInfoProtocol {
    public override class var implements: [COMImplements] { [
        .init(IRestrictedErrorInfoProjection.self)
    ] }

    public override init(error: Error) {
        super.init(error: error)
    }

    public func originate(captureContext: Bool) {
        WinRTError.originate(hresult: hresult, message: description, restrictedErrorInfo: self)
        if captureContext { try? WinRTError.captureContext(hresult: hresult) }
    }

    public override func toABI(setErrorInfo: Bool = true) -> HResult.Value {
        if setErrorInfo { try? WinRTError.setRestrictedErrorInfo(self) }
        return hresult.value
    }

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

    public var reference: String? { get throws { throw COMError.fail } }
}