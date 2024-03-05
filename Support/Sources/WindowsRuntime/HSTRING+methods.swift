import WindowsRuntime_ABI
import COM

extension WindowsRuntime_ABI.SWRT_HString {
    public static func create(_ value: String) throws -> WindowsRuntime_ABI.SWRT_HString? {
        if value.isEmpty { return nil }

        let codeUnitCount = value.utf16.count

        // Preallocate and fill a UTF-16 HSTRING_BUFFER
        var buffer: WindowsRuntime_ABI.SWRT_HStringBuffer? = nil
        var pointer: UnsafeMutablePointer<UInt16>? = nil
        try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsPreallocateStringBuffer(UInt32(codeUnitCount), &pointer, &buffer))
        guard let pointer else { throw HResult.Error.pointer }
        _ = UnsafeMutableBufferPointer(start: pointer, count: codeUnitCount).initialize(from: value.utf16)

        var result: WindowsRuntime_ABI.SWRT_HString?
        do { try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsPromoteStringBuffer(buffer, &result)) }
        catch {
            WindowsRuntime_ABI.SWRT_WindowsDeleteStringBuffer(buffer)
            throw error
        }

        return result
    }

    public static func delete(_ value: WindowsRuntime_ABI.SWRT_HString?) {
        let hr = WindowsRuntime_ABI.SWRT_WindowsDeleteString(value)
        assert(HResult.isSuccess(hr), "Failed to delete HSTRING")
    }

    public static func toStringAndDelete(_ value: WindowsRuntime_ABI.SWRT_HString?) -> String {
        let result = value.toString()
        delete(value)
        return result
    }
}

extension Optional where Wrapped == WindowsRuntime_ABI.SWRT_HString {
    public func duplicate() throws -> Self {
        var result: WindowsRuntime_ABI.SWRT_HString?
        try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsDuplicateString(self, &result))
        return result
    }

    public func toString() -> String {
        var length: UInt32 = 0
        guard let ptr = WindowsRuntime_ABI.SWRT_WindowsGetStringRawBuffer(self, &length) else { return "" }
        let buffer: UnsafeBufferPointer<UTF16.CodeUnit> = .init(start: ptr, count: Int(length))
        return String(decoding: buffer, as: UTF16.self)
    }
}
