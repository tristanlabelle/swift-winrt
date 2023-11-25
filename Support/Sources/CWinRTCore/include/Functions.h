#pragma once

#include "WinRT.h"

ABI_HResult ABI_WindowsCreateString(const char16_t* sourceString, uint32_t length, ABI_HString *string);
ABI_HResult ABI_WindowsDeleteString(ABI_HString string);
ABI_HResult ABI_WindowsDuplicateString(ABI_HString string, ABI_HString *newString);
const char16_t* ABI_WindowsGetStringRawBuffer(ABI_HString string, uint32_t *length);

typedef enum ABI_RO_INIT_TYPE {
  ABI_RO_INIT_SINGLETHREADED = 0,
  ABI_RO_INIT_MULTITHREADED = 1
} ABI_RO_INIT_TYPE;

ABI_HResult ABI_RoGetActivationFactory(ABI_HString activatableClassId, ABI_Guid* iid, void **factory);
ABI_HResult ABI_RoInitialize(ABI_RO_INIT_TYPE initType);
void ABI_RoUninitialize();