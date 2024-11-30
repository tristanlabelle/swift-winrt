#pragma once

#include "SWRT/windows/unknwn.h"

// ICOMTest
typedef struct SWRT_ICOMTest {
    struct SWRT_ICOMTest_VirtualTable* VirtualTable;
} SWRT_ICOMTest;

struct SWRT_ICOMTest_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_ICOMTest* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_ICOMTest* _this);
    uint32_t (__stdcall *Release)(SWRT_ICOMTest* _this);
    SWRT_HResult (__stdcall *COMTest)(SWRT_ICOMTest* _this);
};
