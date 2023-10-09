import CABI
import COM

extension HSTRING {
    public static func create(_ value: String) throws -> HSTRING? {
        let chars = Array(value.utf16)
        return try chars.withUnsafeBufferPointer {
            var result: HSTRING?
            try HResult.throwIfFailed(CABI.WindowsCreateString($0.baseAddress!, UInt32(chars.count), &result))
            return result
        }
    }

    public static func delete(_ value: HSTRING?) {
        let hr = CABI.WindowsDeleteString(value)
        assert(HResult.isSuccess(hr), "Failed to delete HSTRING")
    }

    public static func toStringAndDelete(_ value: HSTRING?) -> String {
        let result = value.toString()
        delete(value)
        return result
    }
}

extension Optional where Wrapped == HSTRING {
    public func duplicate() throws -> Self {
        var result: HSTRING?
        try HResult.throwIfFailed(CABI.WindowsDuplicateString(self, &result))
        return result
    }

    public func toString() -> String {
        var length: UInt32 = 0
        guard let ptr = CABI.WindowsGetStringRawBuffer(self, &length) else { return "" }
        let buffer: UnsafeBufferPointer<UTF16.CodeUnit> = .init(start: ptr, count: Int(length))
        return String(decoding: buffer, as: UTF16.self)
    }
}
