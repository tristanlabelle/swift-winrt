#include "WinRT.h"
#include "Functions.h"

#include <Windows.h>
#include <winstring.h>
#include <roapi.h>

ABI_HResult ABI_WindowsCreateString(const char16_t* sourceString, uint32_t length, ABI_HString *string) {
    return (ABI_HResult)WindowsCreateString((PCNZWCH)sourceString, (UINT32)length, (HSTRING*)string);
}

ABI_HResult ABI_WindowsDeleteString(ABI_HString string) {
    return (ABI_HResult)WindowsDeleteString((HSTRING)string);
}

ABI_HResult ABI_WindowsDuplicateString(ABI_HString string, ABI_HString *newString) {
    return (ABI_HResult)WindowsDuplicateString((HSTRING)string, (HSTRING*)newString);
}

const char16_t* ABI_WindowsGetStringRawBuffer(ABI_HString string, uint32_t *length) {
    return (const char16_t*)WindowsGetStringRawBuffer((HSTRING)string, (UINT32**)length);
}

ABI_HResult ABI_RoGetActivationFactory(ABI_HString activatableClassId, ABI_Guid* iid, void **factory) {
    return (ABI_HResult)RoGetActivationFactory((HSTRING)activatableClassId, (IID*)iid, factory);
}

ABI_HResult ABI_RoInitialize(ABI_RO_INIT_TYPE initType) {
    return (ABI_HResult)RoInitialize((RO_INIT_TYPE)initType);
}

void ABI_RoUninitialize() {
    RoUninitialize();
}