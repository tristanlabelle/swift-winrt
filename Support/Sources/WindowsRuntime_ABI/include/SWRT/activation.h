#pragma once

#include "SWRT/inspectable.h"

// IActivationFactory
typedef struct SWRT_IActivationFactory {
    struct SWRT_IActivationFactory_VirtualTable* VirtualTable;
} SWRT_IActivationFactory;

struct SWRT_IActivationFactory_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IActivationFactory* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IActivationFactory* _this);
    uint32_t (__stdcall *Release)(SWRT_IActivationFactory* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IActivationFactory* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IActivationFactory* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IActivationFactory* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *ActivateInstance)(SWRT_IActivationFactory* _this, SWRT_IInspectable** instance);
};
