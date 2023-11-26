#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <uchar.h>

// GUID
typedef struct SWRT_Guid {
    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t Data4[8];
} SWRT_Guid;

// HRESULT
typedef int32_t SWRT_HResult;

// IUnknown
typedef struct SWRT_IUnknown SWRT_IUnknown;

struct SWRT_IUnknownVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IUnknown* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IUnknown* _this);
    uint32_t (__stdcall *Release)(SWRT_IUnknown* _this);
};

typedef struct SWRT_IUnknown {
    struct SWRT_IUnknownVTable* lpVtbl;
} SWRT_IUnknown;
