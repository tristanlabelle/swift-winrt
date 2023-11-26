#pragma once

#include "COM.h"

// HSTRING
struct SWRT_HString_ {};

typedef struct SWRT_HString_* SWRT_HString;

// TrustLevel
typedef int32_t SWRT_TrustLevel;

// IInspectable
typedef struct SWRT_IInspectable SWRT_IInspectable;

struct SWRT_IInspectableVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IInspectable* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IInspectable* _this);
    uint32_t (__stdcall *Release)(SWRT_IInspectable* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IInspectable* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IInspectable* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IInspectable* _this, SWRT_TrustLevel* trustLevel);
};

typedef struct SWRT_IInspectable {
    struct SWRT_IInspectableVTable* lpVtbl;
} SWRT_IInspectable;

// EventRegistrationToken
typedef struct SWRT_EventRegistrationToken {
    int64_t value;
} SWRT_EventRegistrationToken;

// IActivationFactory
typedef struct SWRT_IActivationFactory SWRT_IActivationFactory;

struct SWRT_IActivationFactoryVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IActivationFactory* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IActivationFactory* _this);
    uint32_t (__stdcall *Release)(SWRT_IActivationFactory* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IActivationFactory* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IActivationFactory* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IActivationFactory* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *ActivateInstance)(SWRT_IActivationFactory* _this, SWRT_IInspectable** instance);
};

typedef struct SWRT_IActivationFactory {
    struct SWRT_IActivationFactoryVTable* lpVtbl;
} SWRT_IActivationFactory;
