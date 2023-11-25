#pragma once

#include "CWinRTCore.h"

typedef struct ABI_IBufferByteAccess ABI_IBufferByteAccess;

typedef struct ABI_IBufferByteAccessVtbl {
    ABI_HResult (__stdcall* QueryInterface)(ABI_IBufferByteAccess* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(ABI_IBufferByteAccess* _this);
    uint32_t (__stdcall* Release)(ABI_IBufferByteAccess* _this);
    ABI_HResult (__stdcall* Buffer)(ABI_IBufferByteAccess* _this, uint8_t** data);
} ABI_IBufferByteAccessVtbl;

struct ABI_IBufferByteAccess {
    struct ABI_IBufferByteAccessVtbl* lpVtbl;
};
