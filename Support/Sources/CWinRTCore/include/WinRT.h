#pragma once

#include "COM.h"

// HSTRING
struct SWRT_HString_ {};

typedef struct SWRT_HString_* SWRT_HString;

// TrustLevel
typedef int32_t SWRT_TrustLevel;

// IInspectable
typedef struct SWRT_IInspectable {
    struct SWRT_IInspectableVTable* lpVtbl;
} SWRT_IInspectable;

struct SWRT_IInspectableVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IInspectable* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IInspectable* _this);
    uint32_t (__stdcall *Release)(SWRT_IInspectable* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IInspectable* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IInspectable* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IInspectable* _this, SWRT_TrustLevel* trustLevel);
};

// EventRegistrationToken
typedef struct SWRT_EventRegistrationToken {
    int64_t value;
} SWRT_EventRegistrationToken;

// IReference<T>
typedef struct SWRT_IReference {
    struct SWRT_IReferenceVTable* lpVtbl;
} SWRT_IReference;

struct SWRT_IReferenceVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IReference* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IReference* _this);
    uint32_t (__stdcall *Release)(SWRT_IReference* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IReference* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IReference* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IReference* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Value)(SWRT_IReference* _this, void* value);
};

// IRestrictedErrorInfo
typedef struct SWRT_IRestrictedErrorInfo {
    struct SWRT_IRestrictedErrorInfoVTable* lpVtbl;
} SWRT_IRestrictedErrorInfo;

struct SWRT_IRestrictedErrorInfoVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IRestrictedErrorInfo* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IRestrictedErrorInfo* _this);
    uint32_t (__stdcall *Release)(SWRT_IRestrictedErrorInfo* _this);
    SWRT_HResult (__stdcall *GetErrorDetails)(SWRT_IRestrictedErrorInfo* _this, SWRT_BStr* description, SWRT_HResult* error, SWRT_BStr* restrictedDescription, SWRT_BStr* capabilitySid);
    SWRT_HResult (__stdcall *GetReference)(SWRT_IRestrictedErrorInfo* _this, SWRT_BStr* reference);
};

// IActivationFactory
typedef struct SWRT_IActivationFactory {
    struct SWRT_IActivationFactoryVTable* lpVtbl;
} SWRT_IActivationFactory;

struct SWRT_IActivationFactoryVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IActivationFactory* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IActivationFactory* _this);
    uint32_t (__stdcall *Release)(SWRT_IActivationFactory* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IActivationFactory* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IActivationFactory* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IActivationFactory* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *ActivateInstance)(SWRT_IActivationFactory* _this, SWRT_IInspectable** instance);
};
