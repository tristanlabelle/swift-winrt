#pragma once

#include "SWRT/windows/BaseTsd.h"
#include "SWRT/windows/winstring.h"
#include "SWRT/windows/activation.h"

typedef SWRT_HResult(__stdcall *SWRT_DllGetActivationFactory)(SWRT_HString activatableClassId, SWRT_IActivationFactory** factory);