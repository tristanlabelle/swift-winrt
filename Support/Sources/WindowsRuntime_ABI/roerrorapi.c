#include "SWRT/roerrorapi.h"

#include <Windows.h>
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