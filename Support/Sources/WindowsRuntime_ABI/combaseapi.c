#include "SWRT/combaseapi.h"

#include <Windows.h>
#include <combaseapi.h>

SWRT_HResult SWRT_CoCreateFreeThreadedMarshaler(SWRT_IUnknown* punkOuter, SWRT_IUnknown** ppunkMarshal) {
    return (SWRT_HResult)CoCreateFreeThreadedMarshaler((IUnknown*)punkOuter, (IUnknown**)ppunkMarshal);
}