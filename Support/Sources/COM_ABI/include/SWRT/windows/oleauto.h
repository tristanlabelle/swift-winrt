#pragma once

#include <stdint.h>
#include "SWRT/windows/wtypes.h"
#include "SWRT/windows/oaidl.h"

SWRT_HResult SWRT_CreateErrorInfo(SWRT_ICreateErrorInfo ** pperrinfo);
SWRT_HResult SWRT_GetErrorInfo(uint32_t dwReserved, SWRT_IErrorInfo** pperrinfo);
SWRT_HResult SWRT_SetErrorInfo(uint32_t dwReserved, SWRT_IErrorInfo* perrinfo);
SWRT_BStr SWRT_SysAllocString(const char16_t* strIn);
SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui);
void SWRT_SysFreeString(SWRT_BStr bstrString);
uint32_t SWRT_SysStringLen(SWRT_BStr pbstr);