public protocol COMError: Error {
    var hresult: HResult { get }
}

extension HResult {
    public func throwIfFailed() throws {
        if let error = Error(hresult: self) { throw error }
    }

    @discardableResult
    public static func throwIfFailed(_ hr: Value) throws -> Value {
        try HResult(hr).throwIfFailed()
        return hr
    }

    public static func `catch`(_ block: () throws -> Void) -> HResult {
        do {
            try block()
            return HResult.ok
        } catch let error as COMError {
            return error.hresult
        } catch {
            return HResult.fail
        }
    }

    public static func catchValue(_ block: () throws -> Void) -> Value {
        `catch`(block).value
    }

    /// A Swift error for a failed HResult value.
    public struct Error: COMError, Hashable, CustomStringConvertible {
        public static let fail = Self(failed: HResult.fail)
        public static let invalidArg = Self(failed: HResult.invalidArg)
        public static let notImpl = Self(failed: HResult.notImpl)
        public static let noInterface = Self(failed: HResult.noInterface)
        public static let outOfMemory = Self(failed: HResult.outOfMemory)

        public let hresult: HResult // Invariant: isFailure

        private init(failed hresult: HResult) {
            self.hresult = hresult
        }

        public init?(hresult: HResult) {
            if hresult.isSuccess { return nil }
            self.hresult = hresult
        }

        public init?(hresult: Value) {
            self.init(hresult: HResult(hresult))
        }

        public var description: String { hresult.description }
    }
}