#pragma once

#include "SWRT/windows/unknwn.h"

typedef struct SWRT_IMemoryBufferByteAccess SWRT_IMemoryBufferByteAccess;

struct SWRT_IMemoryBufferByteAccess_VirtualTable {
    SWRT_HResult (__stdcall* QueryInterface)(SWRT_IMemoryBufferByteAccess* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(SWRT_IMemoryBufferByteAccess* _this);
    uint32_t (__stdcall* Release)(SWRT_IMemoryBufferByteAccess* _this);
    SWRT_HResult (__stdcall* GetBuffer)(SWRT_IMemoryBufferByteAccess* _this, uint8_t** value, uint32_t* capacity);
};

struct SWRT_IMemoryBufferByteAccess {
    struct SWRT_IMemoryBufferByteAccess_VirtualTable* VirtualTable;
};
