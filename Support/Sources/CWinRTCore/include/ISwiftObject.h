#pragma once

#include "CWinRTCore.h"

typedef struct ABI_ISwiftObject ABI_ISwiftObject;

typedef struct ABI_ISwiftObjectVtbl {
    ABI_HResult (__stdcall* QueryInterface)(ABI_ISwiftObject* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(ABI_ISwiftObject* _this);
    uint32_t (__stdcall* Release)(ABI_ISwiftObject* _this);
    void* (__stdcall* GetSwiftObject)(ABI_ISwiftObject* _this);
} ABI_ISwiftObjectVtbl;

struct ABI_ISwiftObject {
    struct ABI_ISwiftObjectVtbl* lpVtbl;
};