#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <uchar.h>

// GUID
typedef struct ABI_Guid {
    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t Data4[8];
} ABI_Guid;

// HRESULT
typedef int32_t ABI_HResult;

// IUnknown
typedef struct ABI_IUnknown ABI_IUnknown;

struct ABI_IUnknownVTable {
    ABI_HResult (__stdcall *QueryInterface)(ABI_IUnknown* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(ABI_IUnknown* _this);
    uint32_t (__stdcall *Release)(ABI_IUnknown* _this);
};

typedef struct ABI_IUnknown {
    struct ABI_IUnknownVTable* lpVtbl;
} ABI_IUnknown;
