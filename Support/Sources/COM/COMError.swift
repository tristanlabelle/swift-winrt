/// Protocol for errors which result from a COM error HRESULT.
public protocol COMError: Error {
    var hresult: HResult { get }
}