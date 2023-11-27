#pragma once

#include "WinRT.h"

SWRT_BStr SWRT_SysAllocString(const char16_t* strIn);
SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui);
void SWRT_SysFreeString(SWRT_BStr bstrString);
uint32_t SWRT_SysStringLen(SWRT_BStr pbstr);

SWRT_HResult SWRT_WindowsCreateString(const char16_t* sourceString, uint32_t length, SWRT_HString *string);
SWRT_HResult SWRT_WindowsDeleteString(SWRT_HString string);
SWRT_HResult SWRT_WindowsDuplicateString(SWRT_HString string, SWRT_HString *newString);
const char16_t* SWRT_WindowsGetStringRawBuffer(SWRT_HString string, uint32_t *length);

typedef enum SWRT_RO_INIT_TYPE {
  SWRT_RO_INIT_SINGLETHREADED = 0,
  SWRT_RO_INIT_MULTITHREADED = 1
} SWRT_RO_INIT_TYPE;

SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void **factory);
SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType);
void SWRT_RoUninitialize();