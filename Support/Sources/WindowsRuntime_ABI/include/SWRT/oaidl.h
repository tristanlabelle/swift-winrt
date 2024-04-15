#pragma once

#include "SWRT/oleauto.h"
#include "SWRT/unknwn.h"

typedef struct SWRT_IErrorInfo {
    struct SWRT_IErrorInfo_VirtualTable* VirtualTable;
} SWRT_IErrorInfo;

struct SWRT_IErrorInfo_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IErrorInfo* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IErrorInfo* _this);
    uint32_t (__stdcall *Release)(SWRT_IErrorInfo* _this);
    SWRT_HResult (__stdcall *GetGUID)(SWRT_IErrorInfo* _this, SWRT_Guid* guid);
    SWRT_HResult (__stdcall *GetSource)(SWRT_IErrorInfo* _this, SWRT_BStr* source);
    SWRT_HResult (__stdcall *GetDescription)(SWRT_IErrorInfo* _this, SWRT_BStr* description);
    SWRT_HResult (__stdcall *GetHelpFile)(SWRT_IErrorInfo* _this, SWRT_BStr* helpFile);
    SWRT_HResult (__stdcall *GetHelpContext)(SWRT_IErrorInfo* _this, uint32_t* helpContext);
};
