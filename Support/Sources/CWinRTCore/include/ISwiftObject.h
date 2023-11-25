#pragma once

#include "COM.h"

typedef struct ABI_ISwiftObject ABI_ISwiftObject;

struct ABI_ISwiftObjectVTable {
    ABI_HResult (__stdcall* QueryInterface)(ABI_ISwiftObject* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(ABI_ISwiftObject* _this);
    uint32_t (__stdcall* Release)(ABI_ISwiftObject* _this);
    void* (__stdcall* GetSwiftObject)(ABI_ISwiftObject* _this);
};

struct ABI_ISwiftObject {
    struct ABI_ISwiftObjectVTable* lpVtbl;
};