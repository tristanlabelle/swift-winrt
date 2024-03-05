#pragma once

#include "WinRT.h"

// oleauto.h
SWRT_BStr SWRT_SysAllocString(const char16_t* strIn);
SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui);
void SWRT_SysFreeString(SWRT_BStr bstrString);
uint32_t SWRT_SysStringLen(SWRT_BStr pbstr);

// winstring.h
SWRT_HResult SWRT_WindowsCreateString(const char16_t* sourceString, uint32_t length, SWRT_HString* string);
SWRT_HResult SWRT_WindowsDeleteString(SWRT_HString string);
SWRT_HResult SWRT_WindowsDeleteStringBuffer(SWRT_HStringBuffer bufferHandle);
SWRT_HResult SWRT_WindowsDuplicateString(SWRT_HString string, SWRT_HString* newString);
const char16_t* SWRT_WindowsGetStringRawBuffer(SWRT_HString string, uint32_t* length);
SWRT_HResult SWRT_WindowsPreallocateStringBuffer(uint32_t length, char16_t** charBuffer, SWRT_HStringBuffer* bufferHandle);
SWRT_HResult SWRT_WindowsPromoteStringBuffer(SWRT_HStringBuffer bufferHandle, SWRT_HString* string);

// roapi.h
typedef enum SWRT_RO_INIT_TYPE {
  SWRT_RO_INIT_SINGLETHREADED = 0,
  SWRT_RO_INIT_MULTITHREADED = 1
} SWRT_RO_INIT_TYPE;

SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void** factory);
SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType);
void SWRT_RoUninitialize();

// roerrorapi.h
SWRT_HResult SWRT_GetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
void SWRT_RoClearError();
SWRT_HResult SWRT_RoGetMatchingRestrictedErrorInfo(SWRT_HResult hrIn, SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
bool SWRT_RoOriginateErrorW(SWRT_HResult error, uint32_t cchMax, const char16_t* message);