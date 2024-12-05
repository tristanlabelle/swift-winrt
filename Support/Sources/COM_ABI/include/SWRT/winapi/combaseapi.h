#pragma once

#include "SWRT/winapi/BaseTsd.h"
#include "SWRT/winapi/unknwn.h"

SWRT_HResult SWRT_CoCreateFreeThreadedMarshaler(SWRT_IUnknown* punkOuter, SWRT_IUnknown** ppunkMarshal);