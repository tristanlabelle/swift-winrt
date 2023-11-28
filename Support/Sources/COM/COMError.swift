public protocol COMError: Error {
    var hresult: HResult { get }
}