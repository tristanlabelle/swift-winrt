#include "SWRT/roapi.h"

#include <Windows.h>
#include <roapi.h>

SWRT_HResult SWRT_RoGetActivationFactory(SWRT_HString activatableClassId, SWRT_Guid* iid, void** factory) {
    return (SWRT_HResult)RoGetActivationFactory((HSTRING)activatableClassId, (IID*)iid, factory);
}

SWRT_HResult SWRT_RoInitialize(SWRT_RO_INIT_TYPE initType) {
    return (SWRT_HResult)RoInitialize((RO_INIT_TYPE)initType);
}

void SWRT_RoUninitialize() {
    RoUninitialize();
}
