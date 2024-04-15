#pragma once

#include "SWRT/unknwn.h"
#include "SWRT/winstring.h"

// TrustLevel
typedef int32_t SWRT_TrustLevel;

// IInspectable
typedef struct SWRT_IInspectable {
    struct SWRT_IInspectable_VirtualTable* VirtualTable;
} SWRT_IInspectable;

struct SWRT_IInspectable_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IInspectable* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IInspectable* _this);
    uint32_t (__stdcall *Release)(SWRT_IInspectable* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IInspectable* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IInspectable* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IInspectable* _this, SWRT_TrustLevel* trustLevel);
};
