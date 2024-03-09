#include "SWRT/winstring.h"

#include <winstring.h>

SWRT_HResult SWRT_WindowsCreateString(const char16_t* sourceString, uint32_t length, SWRT_HString* string) {
    return (SWRT_HResult)WindowsCreateString((PCNZWCH)sourceString, (UINT32)length, (HSTRING*)string);
}

SWRT_HResult SWRT_WindowsDeleteString(SWRT_HString string) {
    return (SWRT_HResult)WindowsDeleteString((HSTRING)string);
}

SWRT_HResult SWRT_WindowsDeleteStringBuffer(SWRT_HStringBuffer bufferHandle) {
    return (SWRT_HResult)WindowsDeleteStringBuffer((HSTRING_BUFFER)bufferHandle);
}

SWRT_HResult SWRT_WindowsDuplicateString(SWRT_HString string, SWRT_HString *newString) {
    return (SWRT_HResult)WindowsDuplicateString((HSTRING)string, (HSTRING*)newString);
}

const char16_t* SWRT_WindowsGetStringRawBuffer(SWRT_HString string, uint32_t *length) {
    return (const char16_t*)WindowsGetStringRawBuffer((HSTRING)string, (UINT32*)length);
}

SWRT_HResult SWRT_WindowsPreallocateStringBuffer(uint32_t length, char16_t** charBuffer, SWRT_HStringBuffer* bufferHandle) {
    return (SWRT_HResult)WindowsPreallocateStringBuffer((UINT32)length, (PWSTR*)charBuffer, (HSTRING_BUFFER*)bufferHandle);
}

SWRT_HResult SWRT_WindowsPromoteStringBuffer(SWRT_HStringBuffer bufferHandle, SWRT_HString* string) {
    return (SWRT_HResult)WindowsPromoteStringBuffer((HSTRING_BUFFER)bufferHandle, (HSTRING*)string);
}
