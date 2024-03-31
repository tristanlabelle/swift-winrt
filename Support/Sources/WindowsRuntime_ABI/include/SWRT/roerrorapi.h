#pragma once

#include <stdbool.h>
#include "SWRT/restrictederrorinfo.h"
#include "SWRT/winstring.h"

SWRT_HResult SWRT_GetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
void SWRT_RoClearError();
SWRT_HResult SWRT_RoGetMatchingRestrictedErrorInfo(SWRT_HResult hrIn, SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
bool SWRT_RoOriginateError(SWRT_HResult error, SWRT_HString message);
bool SWRT_RoOriginateErrorW(SWRT_HResult error, uint32_t cchMax, const char16_t* message);