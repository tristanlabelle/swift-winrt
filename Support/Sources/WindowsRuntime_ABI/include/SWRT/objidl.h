#pragma once

#include "SWRT/oleauto.h"
#include "SWRT/unknwn.h"

// IAgileObject
typedef struct SWRT_IAgileObject {
    struct SWRT_IAgileObjectVTable* lpVtbl;
} SWRT_IAgileObject;

struct SWRT_IAgileObjectVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IAgileObject* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IAgileObject* _this);
    uint32_t (__stdcall *Release)(SWRT_IAgileObject* _this);
};
