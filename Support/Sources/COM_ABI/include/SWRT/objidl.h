#pragma once

#include "SWRT/guiddef.h"
#include "SWRT/oleauto.h"
#include "SWRT/unknwn.h"

// IAgileObject
typedef struct SWRT_IAgileObject {
    struct SWRT_IAgileObject_VirtualTable* VirtualTable;
} SWRT_IAgileObject;

struct SWRT_IAgileObject_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IAgileObject* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IAgileObject* _this);
    uint32_t (__stdcall *Release)(SWRT_IAgileObject* _this);
};

// IStream
typedef struct SWRT_IStream SWRT_IStream;

// IMarshal
typedef struct SWRT_IMarshal {
    struct SWRT_IMarshal_VirtualTable* VirtualTable;
} SWRT_IMarshal;

struct SWRT_IMarshal_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IMarshal* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IMarshal* _this);
    uint32_t (__stdcall *Release)(SWRT_IMarshal* _this);
    SWRT_HResult (__stdcall *GetUnmarshalClass)(SWRT_IMarshal *_this, SWRT_Guid* riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, SWRT_Guid* pCid);
    SWRT_HResult (__stdcall *GetMarshalSizeMax)(SWRT_IMarshal *_this, SWRT_Guid* riid, void* pv, uint32_t dwDestContext, void* pvDestContext, uint32_t mshlflags, uint32_t* pSize);
    SWRT_HResult (__stdcall *MarshalInterface)(SWRT_IMarshal *_this, SWRT_IStream* pStm, SWRT_Guid* riid, void *pv, uint32_t dwDestContext, void *pvDestContext, uint32_t mshlflags);
    SWRT_HResult (__stdcall *UnmarshalInterface)(SWRT_IMarshal *_this, SWRT_IStream* pStm, SWRT_Guid* riid, void **ppv);
    SWRT_HResult (__stdcall *ReleaseMarshalData)(SWRT_IMarshal *_this, SWRT_IStream* pStm);
    SWRT_HResult (__stdcall *DisconnectObject)(SWRT_IMarshal *_this, uint32_t dwReserved);
};