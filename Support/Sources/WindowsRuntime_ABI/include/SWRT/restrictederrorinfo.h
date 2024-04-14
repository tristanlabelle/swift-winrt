#pragma once

#include "SWRT/oleauto.h"
#include "SWRT/unknwn.h"

typedef struct SWRT_IRestrictedErrorInfo {
    struct SWRT_IRestrictedErrorInfo_VirtualTable* VirtualTable;
} SWRT_IRestrictedErrorInfo;

struct SWRT_IRestrictedErrorInfo_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IRestrictedErrorInfo* _Nonnull _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IRestrictedErrorInfo* _Nonnull _this);
    uint32_t (__stdcall *Release)(SWRT_IRestrictedErrorInfo* _Nonnull _this);
    SWRT_HResult (__stdcall *GetErrorDetails)(SWRT_IRestrictedErrorInfo* _Nonnull _this, SWRT_BStr* description, SWRT_HResult* error, SWRT_BStr* restrictedDescription, SWRT_BStr* capabilitySid);
    SWRT_HResult (__stdcall *GetReference)(SWRT_IRestrictedErrorInfo* _Nonnull _this, SWRT_BStr* reference);
};
