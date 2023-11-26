#include "WinRT.h"
#include "Functions.h"

#include <Windows.h>
#include <winstring.h>
#include <roapi.h>

SWRT_HResult SWRT_WindowsCreateString(const char16_t* sourceString, uint32_t length, SWRT_HString *string) {
    return (SWRT_HResult)WindowsCreateString((PCNZWCH)sourceString, (UINT32)length, (HSTRING*)string);
}

SWRT_HResult SWRT_WindowsDeleteString(SWRT_HString string) {
    return (SWRT_HResult)WindowsDeleteString((HSTRING)string);
}

SWRT_HResult SWRT_WindowsDuplicateString(SWRT_HString string, SWRT_HString *newString) {
    return (SWRT_HResult)WindowsDuplicateString((HSTRING)string, (HSTRING*)newString);
}

const char16_t* SWRT_WindowsGetStringRawBuffer(SWRT_HString string, uint32_t *length) {
    return (const char16_t*)WindowsGetStringRawBuffer((HSTRING)string, (UINT32**)length);
}

SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void **factory) {
    return (SWRT_HResult)RoGetActivationFactory((HSTRING)activatableClassId, (IID*)iid, factory);
}

SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType) {
    return (SWRT_HResult)RoInitialize((RO_INIT_TYPE)initType);
}

void SWRT_RoUninitialize() {
    RoUninitialize();
}