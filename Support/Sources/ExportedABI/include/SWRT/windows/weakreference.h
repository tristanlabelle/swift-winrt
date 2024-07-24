#pragma once

#include "SWRT/windows/inspectable.h"

typedef struct SWRT_IWeakReference {
    struct SWRT_IWeakReference_VirtualTable* VirtualTable;
} SWRT_IWeakReference;

struct SWRT_IWeakReference_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IWeakReference* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IWeakReference* _this);
    uint32_t (__stdcall *Release)(SWRT_IWeakReference* _this);
    SWRT_HResult (__stdcall *Resolve)(SWRT_IWeakReference* _this, SWRT_Guid* riid, SWRT_IInspectable** objectReference);
};

typedef struct SWRT_IWeakReferenceSource {
    struct SWRT_IWeakReferenceSource_VirtualTable* VirtualTable;
} SWRT_IWeakReferenceSource;

struct SWRT_IWeakReferenceSource_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IWeakReferenceSource* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IWeakReferenceSource* _this);
    uint32_t (__stdcall *Release)(SWRT_IWeakReferenceSource* _this);
    SWRT_HResult (__stdcall *GetWeakReference)(SWRT_IWeakReferenceSource* _this, SWRT_IWeakReference** weakReference);
};
