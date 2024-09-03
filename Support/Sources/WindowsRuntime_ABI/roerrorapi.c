#include "SWRT/windows/roerrorapi.h"

#include <Windows.h>
#include <roerrorapi.h>

SWRT_HResult SWRT_GetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo) {
    return (SWRT_HResult)GetRestrictedErrorInfo((IRestrictedErrorInfo**)ppRestrictedErrorInfo);
}

SWRT_HResult SWRT_RoCaptureErrorContext(SWRT_HResult hr) {
    return (SWRT_HResult)RoCaptureErrorContext((HRESULT)hr);
}

void SWRT_RoClearError() {
    RoClearError();
}

void SWRT_RoFailFastWithErrorContext(SWRT_HResult hrError) {
    RoFailFastWithErrorContext((HRESULT)hrError);
}

SWRT_HResult SWRT_RoGetErrorReportingFlags(uint32_t* pflags) {
    return (SWRT_HResult)RoGetErrorReportingFlags(pflags);
}

SWRT_HResult SWRT_RoGetMatchingRestrictedErrorInfo(SWRT_HResult hrIn, SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo) {
    return (SWRT_HResult)RoGetMatchingRestrictedErrorInfo((HRESULT)hrIn, (IRestrictedErrorInfo**)ppRestrictedErrorInfo);
}

bool SWRT_RoOriginateError(SWRT_HResult error, SWRT_HString message) {
    return RoOriginateError((HRESULT)error, (HSTRING)message);
}

bool SWRT_RoOriginateErrorW(SWRT_HResult error, uint32_t cchMax, const char16_t* message) {
    return RoOriginateErrorW((HRESULT)error, (UINT)cchMax, (PCWSTR)message);
}

bool SWRT_RoOriginateLanguageException(SWRT_HResult error, SWRT_HString message, SWRT_IUnknown* languageException) {
    return RoOriginateLanguageException((HRESULT)error, (HSTRING)message, (IUnknown*)languageException);
}

SWRT_HResult SWRT_RoReportUnhandledError(SWRT_IRestrictedErrorInfo* pRestrictedErrorInfo) {
    return (SWRT_HResult)RoReportUnhandledError((IRestrictedErrorInfo*)pRestrictedErrorInfo);
}

SWRT_HResult SWRT_RoSetErrorReportingFlags(uint32_t flags) {
    return (SWRT_HResult)RoSetErrorReportingFlags(flags);
}

SWRT_HResult SWRT_RoTransformError(SWRT_HResult oldError, SWRT_HResult newError, SWRT_HString message) {
    return (SWRT_HResult)RoTransformError((HRESULT)oldError, (HRESULT)newError, (HSTRING)message);
}

SWRT_HResult SWRT_SetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo* pRestrictedErrorInfo) {
    return (SWRT_HResult)SetRestrictedErrorInfo((IRestrictedErrorInfo*)pRestrictedErrorInfo);
}