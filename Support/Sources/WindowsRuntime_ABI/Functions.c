#include "Functions.h"

#include <Windows.h>

#include <oleauto.h>
SWRT_BStr SWRT_SysAllocString(const char16_t* strIn) {
    return (SWRT_BStr)SysAllocString((const OLECHAR*)strIn);
}

SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui) {
    return (SWRT_BStr)SysAllocStringLen((const OLECHAR*)strIn, (UINT)ui);
}

void SWRT_SysFreeString(SWRT_BStr bstrString) {
    SysFreeString((BSTR)bstrString);
}

uint32_t SWRT_SysStringLen(SWRT_BStr pbstr) {
    return (uint32_t)SysStringLen((BSTR)pbstr);
}

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

#include <roapi.h>
SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void** factory) {
    return (SWRT_HResult)RoGetActivationFactory((HSTRING)activatableClassId, (IID*)iid, factory);
}

SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType) {
    return (SWRT_HResult)RoInitialize((RO_INIT_TYPE)initType);
}

void SWRT_RoUninitialize() {
    RoUninitialize();
}

#include <roerrorapi.h>
SWRT_HResult SWRT_GetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo) {
    return (SWRT_HResult)GetRestrictedErrorInfo((IRestrictedErrorInfo**)ppRestrictedErrorInfo);
}

void SWRT_RoClearError() {
    RoClearError();
}

SWRT_HResult SWRT_RoGetMatchingRestrictedErrorInfo(SWRT_HResult hrIn, SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo) {
    return (SWRT_HResult)RoGetMatchingRestrictedErrorInfo((HRESULT)hrIn, (IRestrictedErrorInfo**)ppRestrictedErrorInfo);
}

bool SWRT_RoOriginateErrorW(SWRT_HResult error, uint32_t cchMax, const char16_t* message) {
    return RoOriginateErrorW((HRESULT)error, (UINT)cchMax, (PCWSTR)message);
}