#pragma once

#include "CWinRTCore.h"

ABI_HResult WinRT_WindowsCreateString(const char16_t* sourceString, uint32_t  length, ABI_HString *string);
ABI_HResult WinRT_WindowsDeleteString(ABI_HString string);
ABI_HResult WinRT_WindowsDuplicateString(ABI_HString string, ABI_HString *newString);
const char16_t* WinRT_WindowsGetStringRawBuffer(ABI_HString string, uint32_t *length);