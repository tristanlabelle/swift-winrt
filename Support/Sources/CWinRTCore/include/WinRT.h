#pragma once

#include "COM.h"

// HSTRING
struct ABI_HString_ {};

typedef struct ABI_HString_* ABI_HString;

// TrustLevel
typedef int32_t ABI_TrustLevel;

// IInspectable
typedef struct ABI_IInspectable ABI_IInspectable;

struct ABI_IInspectableVTable {
    ABI_HResult (__stdcall *QueryInterface)(ABI_IInspectable* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(ABI_IInspectable* _this);
    uint32_t (__stdcall *Release)(ABI_IInspectable* _this);
    ABI_HResult (__stdcall *GetIids)(ABI_IInspectable* _this, uint32_t* iidCount, ABI_Guid** iids);
    ABI_HResult (__stdcall *GetRuntimeClassName)(ABI_IInspectable* _this, ABI_HString* className);
    ABI_HResult (__stdcall *GetTrustLevel)(ABI_IInspectable* _this, ABI_TrustLevel* trustLevel);
};

typedef struct ABI_IInspectable {
    struct ABI_IInspectableVTable* lpVtbl;
} ABI_IInspectable;

// EventRegistrationToken
typedef struct ABI_EventRegistrationToken {
    int64_t value;
} ABI_EventRegistrationToken;

// IActivationFactory
typedef struct ABI_IActivationFactory ABI_IActivationFactory;

struct ABI_IActivationFactoryVTable {
    ABI_HResult (__stdcall *QueryInterface)(ABI_IActivationFactory* _this, ABI_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(ABI_IActivationFactory* _this);
    uint32_t (__stdcall *Release)(ABI_IActivationFactory* _this);
    ABI_HResult (__stdcall *GetIids)(ABI_IActivationFactory* _this, uint32_t* iidCount, ABI_Guid** iids);
    ABI_HResult (__stdcall *GetRuntimeClassName)(ABI_IActivationFactory* _this, ABI_HString* className);
    ABI_HResult (__stdcall *GetTrustLevel)(ABI_IActivationFactory* _this, ABI_TrustLevel* trustLevel);
    ABI_HResult (__stdcall *ActivateInstance)(ABI_IActivationFactory* _this, ABI_IInspectable** instance);
};

typedef struct ABI_IActivationFactory {
    struct ABI_IActivationFactoryVTable* lpVtbl;
} ABI_IActivationFactory;
