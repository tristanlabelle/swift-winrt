#pragma once

#include "SWRT/windows/inspectable.h"

// Windows.Foundation.IReference<T>
typedef struct SWRT_WindowsFoundation_IReference {
    struct SWRT_WindowsFoundation_IReference_VirtualTable* VirtualTable;
} SWRT_WindowsFoundation_IReference;

struct SWRT_WindowsFoundation_IReference_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_WindowsFoundation_IReference* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_WindowsFoundation_IReference* _this);
    uint32_t (__stdcall *Release)(SWRT_WindowsFoundation_IReference* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_WindowsFoundation_IReference* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_WindowsFoundation_IReference* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_WindowsFoundation_IReference* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Value)(SWRT_WindowsFoundation_IReference* _this, void* value);
};

// Windows.Foundation.IReferenceArray<T>
typedef struct SWRT_WindowsFoundation_IReferenceArray {
    struct SWRT_WindowsFoundation_IReferenceArray_VirtualTable* VirtualTable;
} SWRT_WindowsFoundation_IReferenceArray;

struct SWRT_WindowsFoundation_IReferenceArray_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_WindowsFoundation_IReferenceArray* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_WindowsFoundation_IReferenceArray* _this);
    uint32_t (__stdcall *Release)(SWRT_WindowsFoundation_IReferenceArray* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_WindowsFoundation_IReferenceArray* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_WindowsFoundation_IReferenceArray* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_WindowsFoundation_IReferenceArray* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Value)(SWRT_WindowsFoundation_IReferenceArray* _this, uint32_t* length, void** value);
};