#pragma once

#include "SWRT/guiddef.h"
#include "SWRT/BaseTsd.h"

// IUnknown
typedef struct SWRT_IUnknown {
    struct SWRT_IUnknown_VirtualTable* VirtualTable;
} SWRT_IUnknown;

struct SWRT_IUnknown_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IUnknown* _Nonnull _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IUnknown* _Nonnull _this);
    uint32_t (__stdcall *Release)(SWRT_IUnknown* _Nonnull _this);
};
