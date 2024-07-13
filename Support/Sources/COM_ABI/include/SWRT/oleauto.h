#pragma once

#include <stdint.h>
#include <uchar.h>

typedef char16_t* SWRT_BStr;

SWRT_BStr SWRT_SysAllocString(const char16_t* strIn);
SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui);
void SWRT_SysFreeString(SWRT_BStr bstrString);
uint32_t SWRT_SysStringLen(SWRT_BStr pbstr);