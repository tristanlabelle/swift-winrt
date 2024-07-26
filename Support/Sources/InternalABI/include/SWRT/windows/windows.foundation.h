#pragma once

#include "SWRT/windows/inspectable.h"

// Windows.Foundation.PropertyType
typedef int32_t SWRT_WindowsFoundation_PropertyType;

// Windows.Foundation.DateTime
typedef struct SWRT_WindowsFoundation_DateTime
{
    int64_t UniversalTime;
} SWRT_WindowsFoundation_DateTime;

// Windows.Foundation.Point
typedef struct SWRT_WindowsFoundation_Point
{
    float X;
    float Y;
} SWRT_WindowsFoundation_Point;

// Windows.Foundation.Rect
typedef struct SWRT_WindowsFoundation_Rect
{
    float X;
    float Y;
    float Width;
    float Height;
} SWRT_WindowsFoundation_Rect;

// Windows.Foundation.Size
typedef struct SWRT_WindowsFoundation_Size
{
    float Width;
    float Height;
} SWRT_WindowsFoundation_Size;

// Windows.Foundation.TimeSpan
typedef struct SWRT_WindowsFoundation_TimeSpan
{
    int64_t Duration;
} SWRT_WindowsFoundation_TimeSpan;


// Windows.Foundation.IPropertyValue
typedef struct SWRT_WindowsFoundation_IPropertyValue {
    struct SWRT_WindowsFoundation_IPropertyValue_VirtualTable* VirtualTable;
} SWRT_WindowsFoundation_IPropertyValue;

struct SWRT_WindowsFoundation_IPropertyValue_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_WindowsFoundation_IPropertyValue* _this);
    uint32_t (__stdcall *Release)(SWRT_WindowsFoundation_IPropertyValue* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *get_Type)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_PropertyType* value);
    SWRT_HResult (__stdcall *get_IsNumericScalar)(SWRT_WindowsFoundation_IPropertyValue* _this, bool* value);
    SWRT_HResult (__stdcall *GetUInt8)(SWRT_WindowsFoundation_IPropertyValue* _this, uint8_t* value);
    SWRT_HResult (__stdcall *GetInt16)(SWRT_WindowsFoundation_IPropertyValue* _this, int16_t* value);
    SWRT_HResult (__stdcall *GetUInt16)(SWRT_WindowsFoundation_IPropertyValue* _this, uint16_t* value);
    SWRT_HResult (__stdcall *GetInt32)(SWRT_WindowsFoundation_IPropertyValue* _this, int32_t* value);
    SWRT_HResult (__stdcall *GetUInt32)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* value);
    SWRT_HResult (__stdcall *GetInt64)(SWRT_WindowsFoundation_IPropertyValue* _this, int64_t* value);
    SWRT_HResult (__stdcall *GetUInt64)(SWRT_WindowsFoundation_IPropertyValue* _this, uint64_t* value);
    SWRT_HResult (__stdcall *GetSingle)(SWRT_WindowsFoundation_IPropertyValue* _this, float* value);
    SWRT_HResult (__stdcall *GetDouble)(SWRT_WindowsFoundation_IPropertyValue* _this, double* value);
    SWRT_HResult (__stdcall *GetChar16)(SWRT_WindowsFoundation_IPropertyValue* _this, char16_t* value);
    SWRT_HResult (__stdcall *GetBoolean)(SWRT_WindowsFoundation_IPropertyValue* _this, bool* value);
    SWRT_HResult (__stdcall *GetString)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_HString* value);
    SWRT_HResult (__stdcall *GetGuid)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_Guid* value);
    SWRT_HResult (__stdcall *GetDateTime)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_DateTime* value);
    SWRT_HResult (__stdcall *GetTimeSpan)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_TimeSpan* value);
    SWRT_HResult (__stdcall *GetPoint)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_Point* value);
    SWRT_HResult (__stdcall *GetSize)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_Size* value);
    SWRT_HResult (__stdcall *GetRect)(SWRT_WindowsFoundation_IPropertyValue* _this, SWRT_WindowsFoundation_Rect* value);
    SWRT_HResult (__stdcall *GetUInt8Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, uint8_t** value);
    SWRT_HResult (__stdcall *GetInt16Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, int16_t** value);
    SWRT_HResult (__stdcall *GetUInt16Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, uint16_t** value);
    SWRT_HResult (__stdcall *GetInt32Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, int32_t** value);
    SWRT_HResult (__stdcall *GetUInt32Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, uint32_t** value);
    SWRT_HResult (__stdcall *GetInt64Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, int64_t** value);
    SWRT_HResult (__stdcall *GetUInt64Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, uint64_t** value);
    SWRT_HResult (__stdcall *GetSingleArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, float** value);
    SWRT_HResult (__stdcall *GetDoubleArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, double** value);
    SWRT_HResult (__stdcall *GetChar16Array)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, char16_t** value);
    SWRT_HResult (__stdcall *GetBooleanArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, bool** value);
    SWRT_HResult (__stdcall *GetStringArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, SWRT_HString** value);
    SWRT_HResult (__stdcall *GetInspectableArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, SWRT_IInspectable*** value);
    SWRT_HResult (__stdcall *GetGuidArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* __valueSize, SWRT_Guid** value);
    SWRT_HResult (__stdcall *GetDateTimeArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* valueLength, SWRT_WindowsFoundation_DateTime** value);
    SWRT_HResult (__stdcall *GetTimeSpanArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* valueLength, SWRT_WindowsFoundation_TimeSpan** value);
    SWRT_HResult (__stdcall *GetPointArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* valueLength, SWRT_WindowsFoundation_Point** value);
    SWRT_HResult (__stdcall *GetSizeArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* valueLength, SWRT_WindowsFoundation_Size** value);
    SWRT_HResult (__stdcall *GetRectArray)(SWRT_WindowsFoundation_IPropertyValue* _this, uint32_t* valueLength, SWRT_WindowsFoundation_Rect** value);
};

// Windows.Foundation.IPropertyValueStatics
typedef struct SWRT_WindowsFoundation_IPropertyValueStatics {
    struct SWRT_WindowsFoundation_IPropertyValueStatics_VirtualTable* VirtualTable;
} SWRT_WindowsFoundation_IPropertyValueStatics;

struct SWRT_WindowsFoundation_IPropertyValueStatics_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_WindowsFoundation_IPropertyValueStatics* _this);
    uint32_t (__stdcall *Release)(SWRT_WindowsFoundation_IPropertyValueStatics* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *CreateEmpty)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt8)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint8_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt16)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, int16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt16)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt32)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, int32_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt32)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt64)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, int64_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt64)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint64_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSingle)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, float value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDouble)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, double value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateChar16)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, char16_t value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateBoolean)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, bool value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateString)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_HString value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInspectable)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_IInspectable* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateGuid)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_Guid value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDateTime)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_WindowsFoundation_DateTime value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateTimeSpan)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_WindowsFoundation_TimeSpan value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreatePoint)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_WindowsFoundation_Point value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSize)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_WindowsFoundation_Size value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateRect)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, SWRT_WindowsFoundation_Rect value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt8Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, uint8_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt16Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, int16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt16Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, uint16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt32Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, int32_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt32Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, uint32_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInt64Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, int64_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateUInt64Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, uint64_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSingleArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, float* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDoubleArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, double* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateChar16Array)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, char16_t* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateBooleanArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, bool* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateStringArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_HString* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateInspectableArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_IInspectable** value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateGuidArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_Guid* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateDateTimeArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_WindowsFoundation_DateTime* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateTimeSpanArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_WindowsFoundation_TimeSpan* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreatePointArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_WindowsFoundation_Point* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateSizeArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_WindowsFoundation_Size* value, SWRT_IInspectable** propertyValue);
    SWRT_HResult (__stdcall *CreateRectArray)(SWRT_WindowsFoundation_IPropertyValueStatics* _this, uint32_t __valueSize, SWRT_WindowsFoundation_Rect* value, SWRT_IInspectable** propertyValue);
};

// // Windows.Foundation.IStringable
typedef struct SWRT_WindowsFoundation_IStringable {
    struct SWRT_WindowsFoundation_IStringable_VirtualTable* VirtualTable;
} SWRT_WindowsFoundation_IStringable;

struct SWRT_WindowsFoundation_IStringable_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_WindowsFoundation_IStringable* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_WindowsFoundation_IStringable* _this);
    uint32_t (__stdcall *Release)(SWRT_WindowsFoundation_IStringable* _this);
    SWRT_HResult (__stdcall *GetIids)(SWRT_WindowsFoundation_IStringable* _this, uint32_t* iidCount, SWRT_Guid** iids);
    SWRT_HResult (__stdcall *GetRuntimeClassName)(SWRT_WindowsFoundation_IStringable* _this, SWRT_HString* className);
    SWRT_HResult (__stdcall *GetTrustLevel)(SWRT_WindowsFoundation_IStringable* _this, SWRT_TrustLevel* trustLevel);
    SWRT_HResult (__stdcall *ToString)(SWRT_WindowsFoundation_IStringable* _this, SWRT_HString* value);
};
