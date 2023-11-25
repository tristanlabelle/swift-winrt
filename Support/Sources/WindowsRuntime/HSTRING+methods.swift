import CWinRTCore
import COM

extension CWinRTCore.ABI_HString {
    public static func create(_ value: String) throws -> CWinRTCore.ABI_HString? {
        let chars = Array(value.utf16)
        return try chars.withUnsafeBufferPointer {
            var result: CWinRTCore.ABI_HString?
            try HResult.throwIfFailed(CWinRTCore.WinRT_WindowsCreateString($0.baseAddress!, UInt32(chars.count), &result))
            return result
        }
    }

    public static func delete(_ value: CWinRTCore.ABI_HString?) {
        let hr = CWinRTCore.WinRT_WindowsDeleteString(value)
        assert(HResult.isSuccess(hr), "Failed to delete HSTRING")
    }

    public static func toStringAndDelete(_ value: CWinRTCore.ABI_HString?) -> String {
        let result = value.toString()
        delete(value)
        return result
    }
}

extension Optional where Wrapped == CWinRTCore.ABI_HString {
    public func duplicate() throws -> Self {
        var result: CWinRTCore.ABI_HString?
        try HResult.throwIfFailed(CWinRTCore.WinRT_WindowsDuplicateString(self, &result))
        return result
    }

    public func toString() -> String {
        var length: UInt32 = 0
        guard let ptr = CWinRTCore.WinRT_WindowsGetStringRawBuffer(self, &length) else { return "" }
        let buffer: UnsafeBufferPointer<UTF16.CodeUnit> = .init(start: ptr, count: Int(length))
        return String(decoding: buffer, as: UTF16.self)
    }
}
