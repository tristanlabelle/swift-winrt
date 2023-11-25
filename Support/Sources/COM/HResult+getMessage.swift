import WinSDK

extension HResult {
    public static func getMessage(_ hr: Value) -> String? {
        let dwFlags: WinSDK.DWORD = WinSDK.DWORD(WinSDK.FORMAT_MESSAGE_ALLOCATE_BUFFER)
            | WinSDK.DWORD(WinSDK.FORMAT_MESSAGE_FROM_SYSTEM)
            | WinSDK.DWORD(WinSDK.FORMAT_MESSAGE_IGNORE_INSERTS)

        var buffer: UnsafeMutablePointer<WinSDK.WCHAR>? = nil
        // When specifying ALLOCATE_BUFFER, lpBuffer is used as an LPWSTR*
        let dwResult: WinSDK.DWORD = withUnsafeMutablePointer(to: &buffer) {
            $0.withMemoryRebound(to: WCHAR.self, capacity: 1) {
                WinSDK.FormatMessageW(
                    dwFlags,
                    /* lpSource: */ nil,
                    /* dwMessageId: */ WinSDK.DWORD(bitPattern: hr),
                    /* dwLanguageId: */ 0,
                    /* lpBuffer*/ $0,
                    /* nSize: */ 0,
                    /* Arguments: */ nil)
            }
        }
        guard let buffer else { return nil }
        defer { WinSDK.LocalFree(buffer) }
        guard dwResult > 0 else { return nil }

        var message = String(decodingCString: buffer, as: UTF16.self)
        // Remove any trailing whitespaces
        while let lastIndex = message.indices.last, message[lastIndex].isWhitespace {
            message.remove(at: lastIndex)
        }
        return message
    }
}