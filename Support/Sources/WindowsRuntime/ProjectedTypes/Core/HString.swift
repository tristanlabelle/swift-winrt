import WindowsRuntime_ABI
import COM

/// Wraps a Windows Runtime HSTRING.
public struct HString: ~Copyable {
    public static var empty: HString { HString(transferring: nil) }

    public let abi: WindowsRuntime_ABI.SWRT_HString?

    public init(transferring abi: WindowsRuntime_ABI.SWRT_HString?) {
        self.abi = abi
    }

    public init(duplicating abi: WindowsRuntime_ABI.SWRT_HString?) throws {
        var duplicated: WindowsRuntime_ABI.SWRT_HString?
        try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsDuplicateString(abi, &duplicated))
        self.init(transferring: duplicated)
    }

    deinit { Self.delete(abi) }

    public static func create(_ value: String) throws -> HString {
        if value.isEmpty { return .empty }
        
        // Preallocate and fill a UTF-16 HSTRING_BUFFER
        var buffer: WindowsRuntime_ABI.SWRT_HStringBuffer? = nil
        var pointer: UnsafeMutablePointer<UInt16>? = nil
        let codeUnitCount = value.utf16.count
        try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsPreallocateStringBuffer(UInt32(codeUnitCount), &pointer, &buffer))
        guard let pointer else { throw HResult.Error.pointer }
        _ = UnsafeMutableBufferPointer(start: pointer, count: codeUnitCount).initialize(from: value.utf16)

        var abi: WindowsRuntime_ABI.SWRT_HString?
        do { try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsPromoteStringBuffer(buffer, &abi)) }
        catch {
            WindowsRuntime_ABI.SWRT_WindowsDeleteStringBuffer(buffer)
            throw error
        }

        return .init(transferring: abi)
    }

    public static func toString(_ abi: WindowsRuntime_ABI.SWRT_HString?) -> String {
        var length: UInt32 = 0
        guard let ptr = WindowsRuntime_ABI.SWRT_WindowsGetStringRawBuffer(abi, &length) else { return "" }
        let buffer: UnsafeBufferPointer<UTF16.CodeUnit> = .init(start: ptr, count: Int(length))
        return String(decoding: buffer, as: UTF16.self)
    }

    public func toString() -> String { Self.toString(abi) }

    public func duplicate() throws -> Self {
        var duplicated: WindowsRuntime_ABI.SWRT_HString?
        try HResult.throwIfFailed(WindowsRuntime_ABI.SWRT_WindowsDuplicateString(abi, &duplicated))
        return .init(transferring: duplicated)
    }

    public static func delete(_ abi: WindowsRuntime_ABI.SWRT_HString?) {
        let hr = WindowsRuntime_ABI.SWRT_WindowsDeleteString(abi)
        assert(HResult.isSuccess(hr), "Failed to delete HSTRING")
    }

    public consuming func detach() -> WindowsRuntime_ABI.SWRT_HString? {
        let abi = self.abi
        discard self
        return abi
    }
}
