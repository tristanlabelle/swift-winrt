extension WinRTError {
    /// Wraps a Swift Error object so it can be associated with an `IRestrictedErrorInfo`.
    internal final class LanguageException: COMExport<IUnknownBinding> {
        public let error: Error

        public init(error: Error) {
            self.error = error
        }
    }
}