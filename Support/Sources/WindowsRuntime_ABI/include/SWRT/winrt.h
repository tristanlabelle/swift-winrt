#pragma once

#include "SWRT/BaseTsd.h"
#include "SWRT/winstring.h"
#include "SWRT/activation.h"

typedef SWRT_HResult(__stdcall *SWRT_DllGetActivationFactory)(SWRT_HString activatableClassId, SWRT_IActivationFactory** factory);