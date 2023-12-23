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

// Windows.Foundation.PropertyType
typedef enum SWRT_PropertyType
{
    Empty            = 0,
    UInt8            = 1,
    Int16            = 2,
    UInt16           = 3,
    Int32            = 4,
    UInt32           = 5,
    Int64            = 6,
    UInt64           = 7,
    Single           = 8,
    Double           = 9,
    Char16           = 10,
    Boolean          = 11,
    String           = 12,
    Inspectable      = 13,
    DateTime         = 14,
    TimeSpan         = 15,
    Guid             = 16,
    Point            = 17,
    Size             = 18,
    Rect             = 19,
    OtherType        = 20,
    UInt8Array       = 1025,
    Int16Array       = 1026,
    UInt16Array      = 1027,
    Int32Array       = 1028,
    UInt32Array      = 1029,
    Int64Array       = 1030,
    UInt64Array      = 1031,
    SingleArray      = 1032,
    DoubleArray      = 1033,
    Char16Array      = 1034,
    BooleanArray     = 1035,
    StringArray      = 1036,
    InspectableArray = 1037,
    DateTimeArray    = 1038,
    TimeSpanArray    = 1039,
    GuidArray        = 1040,
    PointArray       = 1041,
    SizeArray        = 1042,
    RectArray        = 1043,
    OtherTypeArray   = 1044
} SWRT_PropertyType;

// Windows.Foundation.IPropertyValue
typedef struct SWRT_IPropertyValue {
    struct SWRT_IPropertyValueVTable* lpVtbl;
} SWRT_IPropertyValue;

struct SWRT_IPropertyValueVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IPropertyValue* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IPropertyValue* _this);
    uint32_t (__stdcall *Release)(SWRT_IPropertyValue* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IPropertyValue* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IPropertyValue* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IPropertyValue* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Type)(SWRT_IPropertyValue* _this, SWRT_PropertyType* value);
    SWRT_HResult (__stdcall *get_IsNumericScalar)(SWRT_IPropertyValue* _this, bool* value);
    SWRT_HResult (__stdcall *GetUInt8)(SWRT_IPropertyValue* _this, uint8_t* value);
    SWRT_HResult (__stdcall *GetInt16)(SWRT_IPropertyValue* _this, int16_t* value);
    SWRT_HResult (__stdcall *GetUInt16)(SWRT_IPropertyValue* _this, uint16_t* value);
    SWRT_HResult (__stdcall *GetInt32)(SWRT_IPropertyValue* _this, int32_t* value);
    SWRT_HResult (__stdcall *GetUInt32)(SWRT_IPropertyValue* _this, uint32_t* value);
    SWRT_HResult (__stdcall *GetInt64)(SWRT_IPropertyValue* _this, int64_t* value);
    SWRT_HResult (__stdcall *GetUInt64)(SWRT_IPropertyValue* _this, uint64_t* value);
    SWRT_HResult (__stdcall *GetSingle)(SWRT_IPropertyValue* _this, float* value);
    SWRT_HResult (__stdcall *GetDouble)(SWRT_IPropertyValue* _this, double* value);
    SWRT_HResult (__stdcall *GetChar16)(SWRT_IPropertyValue* _this, char16_t* value);
    SWRT_HResult (__stdcall *GetBoolean)(SWRT_IPropertyValue* _this, bool* value);
    SWRT_HResult (__stdcall *GetString)(SWRT_IPropertyValue* _this, SWRT_HString* value);
    SWRT_HResult (__stdcall *GetGuid)(SWRT_IPropertyValue* _this, SWRT_Guid* value);
    void* GetDateTime; // SWRT_HResult (__stdcall *GetDateTime)(SWRT_IPropertyValue* _this, Windows.Foundation.DateTime* value);
    void* GetTimeSpan; // SWRT_HResult (__stdcall *GetTimeSpan)(SWRT_IPropertyValue* _this, Windows.Foundation.TimeSpan* value);
    void* GetPoint; // SWRT_HResult (__stdcall *GetPoint)(SWRT_IPropertyValue* _this, Windows.Foundation.Point* value);
    void* GetSize; // SWRT_HResult (__stdcall *GetSize)(SWRT_IPropertyValue* _this, Windows.Foundation.Size* value);
    void* GetRect; // SWRT_HResult (__stdcall *GetRect)(SWRT_IPropertyValue* _this, Windows.Foundation.Rect* value);
    SWRT_HResult (__stdcall *GetUInt8Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, uint8_t** value);
    SWRT_HResult (__stdcall *GetInt16Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, int16_t** value);
    SWRT_HResult (__stdcall *GetUInt16Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, uint16_t** value);
    SWRT_HResult (__stdcall *GetInt32Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, int32_t** value);
    SWRT_HResult (__stdcall *GetUInt32Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, uint32_t** value);
    SWRT_HResult (__stdcall *GetInt64Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, int64_t** value);
    SWRT_HResult (__stdcall *GetUInt64Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, uint64_t** value);
    SWRT_HResult (__stdcall *GetSingleArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, float** value);
    SWRT_HResult (__stdcall *GetDoubleArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, double** value);
    SWRT_HResult (__stdcall *GetChar16Array)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, char16_t** value);
    SWRT_HResult (__stdcall *GetBooleanArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, bool** value);
    SWRT_HResult (__stdcall *GetStringArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, SWRT_HString** value);
    SWRT_HResult (__stdcall *GetInspectableArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, SWRT_IInspectable*** value);
    SWRT_HResult (__stdcall *GetGuidArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, SWRT_Guid** value);
    void* GetDateTimeArray; // SWRT_HResult (__stdcall *GetDateTimeArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, Windows.Foundation.DateTime** value);
    void* GetTimeSpanArray; // SWRT_HResult (__stdcall *GetTimeSpanArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, Windows.Foundation.TimeSpan** value);
    void* GetPointArray; // SWRT_HResult (__stdcall *GetPointArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, Windows.Foundation.Point** value);
    void* GetSizeArray; // SWRT_HResult (__stdcall *GetSizeArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, Windows.Foundation.Size** value);
    void* GetRectArray; // SWRT_HResult (__stdcall *GetRectArray)(SWRT_IPropertyValue* _this, uint32_t* __valueSize, Windows.Foundation.Rect** value);
};

// Windows.Foundation.IPropertyValueStatics
typedef struct SWRT_IPropertyValueStatics {
    struct SWRT_IPropertyValueStaticsVTable* lpVtbl;
} SWRT_IPropertyValueStatics;

struct SWRT_IPropertyValueStaticsVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IPropertyValueStatics* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IPropertyValueStatics* _this);
    uint32_t (__stdcall *Release)(SWRT_IPropertyValueStatics* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_IPropertyValueStatics* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_IPropertyValueStatics* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_IPropertyValueStatics* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *CreateEmpty)(SWRT_IPropertyValueStatics* _this, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt8)(SWRT_IPropertyValueStatics* _this, uint8_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt16)(SWRT_IPropertyValueStatics* _this, int16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt16)(SWRT_IPropertyValueStatics* _this, uint16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt32)(SWRT_IPropertyValueStatics* _this, int32_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt32)(SWRT_IPropertyValueStatics* _this, uint32_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt64)(SWRT_IPropertyValueStatics* _this, int64_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt64)(SWRT_IPropertyValueStatics* _this, uint64_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSingle)(SWRT_IPropertyValueStatics* _this, float value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDouble)(SWRT_IPropertyValueStatics* _this, double value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateChar16)(SWRT_IPropertyValueStatics* _this, char16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateBoolean)(SWRT_IPropertyValueStatics* _this, bool value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateString)(SWRT_IPropertyValueStatics* _this, SWRT_HString value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInspectable)(SWRT_IPropertyValueStatics* _this, SWRT_IInspectable* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateGuid)(SWRT_IPropertyValueStatics* _this, SWRT_Guid value, SWRT_IInspectable** propertyValue);
    void* CreateDateTime; // SWRT_HResult (__stdcall *CreateDateTime)(SWRT_IPropertyValueStatics* _this, Windows.Foundation.DateTime value, SWRT_IInspectable** propertyValue);
    void* CreateTimeSpan; // SWRT_HResult (__stdcall *CreateTimeSpan)(SWRT_IPropertyValueStatics* _this, Windows.Foundation.TimeSpan value, SWRT_IInspectable** propertyValue);
    void* CreatePoint; // SWRT_HResult (__stdcall *CreatePoint)(SWRT_IPropertyValueStatics* _this, Windows.Foundation.Point value, SWRT_IInspectable** propertyValue);
    void* CreateSize; // SWRT_HResult (__stdcall *CreateSize)(SWRT_IPropertyValueStatics* _this, Windows.Foundation.Size value, SWRT_IInspectable** propertyValue);
    void* CreateRect; // SWRT_HResult (__stdcall *CreateRect)(SWRT_IPropertyValueStatics* _this, Windows.Foundation.Rect value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt8Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, uint8_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt16Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, int16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt16Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, uint16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt32Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, int32_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt32Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, uint32_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt64Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, int64_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt64Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, uint64_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSingleArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, float* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDoubleArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, double* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateChar16Array)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, char16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateBooleanArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, bool* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateStringArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_HString* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInspectableArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_IInspectable** value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateGuidArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_Guid* value, SWRT_IInspectable** propertyValue);
    void* CreateDateTimeArray; // SWRT_HResult (__stdcall *CreateDateTimeArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, Windows.Foundation.DateTime* value, SWRT_IInspectable** propertyValue);
    void* CreateTimeSpanArray; // SWRT_HResult (__stdcall *CreateTimeSpanArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, Windows.Foundation.TimeSpan* value, SWRT_IInspectable** propertyValue);
    void* CreatePointArray; // SWRT_HResult (__stdcall *CreatePointArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, Windows.Foundation.Point* value, SWRT_IInspectable** propertyValue);
    void* CreateSizeArray; // SWRT_HResult (__stdcall *CreateSizeArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, Windows.Foundation.Size* value, SWRT_IInspectable** propertyValue);
    void* CreateRectArray; // SWRT_HResult (__stdcall *CreateRectArray)(SWRT_IPropertyValueStatics* _this, uint32_t __valueSize, Windows.Foundation.Rect* value, SWRT_IInspectable** propertyValue);
};

// Windows.Foundation.IReference<T>
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

// IWeakReference
typedef struct SWRT_IWeakReference {
    struct SWRT_IWeakReferenceVTable* lpVtbl;
} SWRT_IWeakReference;

struct SWRT_IWeakReferenceVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IWeakReference* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IWeakReference* _this);
    uint32_t (__stdcall *Release)(SWRT_IWeakReference* _this);
    SWRT_HResult (__stdcall *Resolve)(SWRT_IWeakReference* _this, SWRT_Guid* riid, SWRT_IInspectable** objectReference);
};

// IWeakReferenceSource
typedef struct SWRT_IWeakReferenceSource {
    struct SWRT_IWeakReferenceSourceVTable* lpVtbl;
} SWRT_IWeakReferenceSource;

struct SWRT_IWeakReferenceSourceVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IWeakReferenceSource* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IWeakReferenceSource* _this);
    uint32_t (__stdcall *Release)(SWRT_IWeakReferenceSource* _this);
    SWRT_HResult (__stdcall *GetWeakReference)(SWRT_IWeakReferenceSource* _this, SWRT_IWeakReference** weakReference);
};
