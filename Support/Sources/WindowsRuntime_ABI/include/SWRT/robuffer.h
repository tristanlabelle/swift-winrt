#pragma once

#include "SWRT/unknwn.h"

typedef struct SWRT_IBufferByteAccess SWRT_IBufferByteAccess;

struct SWRT_IBufferByteAccess_VirtualTable {
    SWRT_HResult (__stdcall* QueryInterface)(SWRT_IBufferByteAccess* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall* AddRef)(SWRT_IBufferByteAccess* _this);
    uint32_t (__stdcall* Release)(SWRT_IBufferByteAccess* _this);
    SWRT_HResult (__stdcall* Buffer)(SWRT_IBufferByteAccess* _this, uint8_t** data);
};

struct SWRT_IBufferByteAccess {
    struct SWRT_IBufferByteAccess_VirtualTable* VirtualTable;
};
