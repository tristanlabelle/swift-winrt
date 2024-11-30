#pragma once

#include "SWRT/windows/inspectable.h"

// IWinRTTest
typedef struct SWRT_IWinRTTest {
    struct SWRT_IWinRTTest_VirtualTable* VirtualTable;
} SWRT_IWinRTTest;

struct SWRT_IWinRTTest_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IWinRTTest* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IWinRTTest* _this);
    uint32_t (__stdcall *Release)(SWRT_IWinRTTest* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IWinRTTest* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IWinRTTest* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IWinRTTest* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *WinRTTest)(SWRT_IWinRTTest* _this);
};
