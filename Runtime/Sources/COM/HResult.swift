import CWinRTCore

public struct HResult: Hashable, CustomStringConvertible {
    public typealias Value = Int32
    public typealias UnsignedValue = UInt32

    public static let ok = HResult(0)
    public static let fail = HResult(unsigned: 0x80004005)
    public static let invalidArg = HResult(unsigned: 0x80070057)
    public static let notImpl = HResult(unsigned: 0x80004001)
    public static let noInterface = HResult(unsigned: 0x80004002)
    public static let outOfMemory = HResult(unsigned: 0x8007000E)

    public var value: Value
    public var unsignedValue: UnsignedValue { UnsignedValue(bitPattern: value) }

    public init(_ value: Value) { self.value = value }
    public init(unsigned: UnsignedValue) { self.value = Value(bitPattern: unsigned) }

    public var isSuccess: Bool { Self.isSuccess(value) }
    public var isFailure: Bool { Self.isFailure(value) }

    public var message: String? { Self.getMessage(value) }

    public var hexValue: String {
        let prepaddedValue = UInt64(unsignedValue) | (UInt64(0xFF) << 32)
        var result = String(prepaddedValue, radix: 16, uppercase: true)
        result.replaceSubrange(result.firstRange(of: "FF")!, with: "0x")
        return result
    }

    public var description: String {
        if let message = self.message {
            return "HRESULT(\(hexValue)): \(message)"
        }

        return "HRESULT(\(hexValue))"
    }

    public static func isSuccess(_ hr: Value) -> Bool { hr >= 0 }
    public static func isFailure(_ hr: Value) -> Bool { hr < 0 }

    public static func getMessage(_ hr: Value) -> String? {
        let dwFlags: DWORD = DWORD(FORMAT_MESSAGE_ALLOCATE_BUFFER)
            | DWORD(FORMAT_MESSAGE_FROM_SYSTEM)
            | DWORD(FORMAT_MESSAGE_IGNORE_INSERTS)

        var buffer: UnsafeMutablePointer<WCHAR>? = nil
        // When specifying ALLOCATE_BUFFER, lpBuffer is used as an LPWSTR*
        let dwResult: DWORD = withUnsafeMutablePointer(to: &buffer) {
            $0.withMemoryRebound(to: WCHAR.self, capacity: 1) {
                CWinRTCore.FormatMessageW(
                    dwFlags,
                    /* lpSource: */ nil,
                    /* dwMessageId: */ DWORD(bitPattern: hr),
                    /* dwLanguageId: */ 0,
                    /* lpBuffer*/ $0,
                    /* nSize: */ 0,
                    /* Arguments: */ nil)
            }
        }
        guard let buffer else { return nil }
        defer { CWinRTCore.LocalFree(buffer) }
        guard dwResult > 0 else { return nil }

        var message = String(decodingCString: buffer, as: UTF16.self)
        // Remove any trailing whitespaces
        while let lastIndex = message.indices.last, message[lastIndex].isWhitespace {
            message.remove(at: lastIndex)
        }
        return message
    }
}