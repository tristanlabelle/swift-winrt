#pragma once

#include <stdint.h>
#include <uchar.h>
#include "SWRT/windows/BaseTsd.h"

typedef struct SWRT_HString_* SWRT_HString;
typedef struct SWRT_HStringBuffer_* SWRT_HStringBuffer;

SWRT_HResult SWRT_WindowsCreateString(const char16_t* sourceString, uint32_t length, SWRT_HString* string);
SWRT_HResult SWRT_WindowsDeleteString(SWRT_HString string);
SWRT_HResult SWRT_WindowsDeleteStringBuffer(SWRT_HStringBuffer bufferHandle);
SWRT_HResult SWRT_WindowsDuplicateString(SWRT_HString string, SWRT_HString* newString);
const char16_t* SWRT_WindowsGetStringRawBuffer(SWRT_HString string, uint32_t* length);
SWRT_HResult SWRT_WindowsPreallocateStringBuffer(uint32_t length, char16_t** charBuffer, SWRT_HStringBuffer* bufferHandle);
SWRT_HResult SWRT_WindowsPromoteStringBuffer(SWRT_HStringBuffer bufferHandle, SWRT_HString* string);