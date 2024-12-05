#pragma once

#include "SWRT/winapi/activation.h"
#include "SWRT/winapi/BaseTsd.h"
#include "SWRT/winapi/winstring.h"

typedef enum SWRT_RO_INIT_TYPE {
  SWRT_RO_INIT_SINGLETHREADED = 0,
  SWRT_RO_INIT_MULTITHREADED = 1
} SWRT_RO_INIT_TYPE;

typedef SWRT_HResult(__stdcall *SWRT_DllGetActivationFactory)(SWRT_HString activatableClassId, SWRT_IActivationFactory** factory);
SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void** factory);
SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType);
void SWRT_RoUninitialize();
