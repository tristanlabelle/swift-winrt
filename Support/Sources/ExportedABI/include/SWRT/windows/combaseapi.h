#pragma once

#include "SWRT/windows/BaseTsd.h"
#include "SWRT/windows/unknwn.h"

SWRT_HResult SWRT_CoCreateFreeThreadedMarshaler(SWRT_IUnknown* punkOuter, SWRT_IUnknown** ppunkMarshal);