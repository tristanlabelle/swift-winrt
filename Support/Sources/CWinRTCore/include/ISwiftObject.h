#pragma once

#include "COM.h"

typedef struct SWRT_ISwiftObject SWRT_ISwiftObject;

struct SWRT_ISwiftObjectVTable {
    SWRT_HResult (__stdcall* QueryInterface)(SWRT_ISwiftObject* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(SWRT_ISwiftObject* _this);
    uint32_t (__stdcall* Release)(SWRT_ISwiftObject* _this);
    void* (__stdcall* GetSwiftObject)(SWRT_ISwiftObject* _this);
};

struct SWRT_ISwiftObject {
    struct SWRT_ISwiftObjectVTable* lpVtbl;
};