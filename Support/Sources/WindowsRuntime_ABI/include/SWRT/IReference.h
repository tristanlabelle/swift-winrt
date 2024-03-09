#pragma once

#include "SWRT/inspectable.h"

// Windows.Foundation.IReference<T>
typedef struct SWRT_IReference {
    struct SWRT_IReferenceVTable* lpVtbl;
} SWRT_IReference;

struct SWRT_IReferenceVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IReference* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IReference* _this);
    uint32_t (__stdcall *Release)(SWRT_IReference* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IReference* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IReference* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IReference* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Value)(SWRT_IReference* _this, void* value);
};
