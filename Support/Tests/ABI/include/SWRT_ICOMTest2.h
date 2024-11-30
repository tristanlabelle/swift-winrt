#pragma once

#include "SWRT/windows/unknwn.h"

// ICOMTest2
typedef struct SWRT_ICOMTest2 {
    struct SWRT_ICOMTest2_VirtualTable* VirtualTable;
} SWRT_ICOMTest2;

struct SWRT_ICOMTest2_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_ICOMTest2* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_ICOMTest2* _this);
    uint32_t (__stdcall *Release)(SWRT_ICOMTest2* _this);
    SWRT_HResult (__stdcall *COMTest2)(SWRT_ICOMTest2* _this);
};
