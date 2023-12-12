#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <uchar.h>

// GUID
typedef struct SWRT_Guid {
    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t Data4[8];
} SWRT_Guid;

// HRESULT
typedef int32_t SWRT_HResult;

// BSTR
typedef char16_t* SWRT_BStr;

// IUnknown
typedef struct SWRT_IUnknown {
    struct SWRT_IUnknownVTable* lpVtbl;
} SWRT_IUnknown;

struct SWRT_IUnknownVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IUnknown* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IUnknown* _this);
    uint32_t (__stdcall *Release)(SWRT_IUnknown* _this);
};

// IAgileObject
typedef struct SWRT_IAgileObject {
    struct SWRT_IAgileObjectVTable* lpVtbl;
} SWRT_IAgileObject;

struct SWRT_IAgileObjectVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IAgileObject* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IAgileObject* _this);
    uint32_t (__stdcall *Release)(SWRT_IAgileObject* _this);
};

// IErrorInfo
typedef struct SWRT_IErrorInfo {
    struct SWRT_IErrorInfoVTable* lpVtbl;
} SWRT_IErrorInfo;

struct SWRT_IErrorInfoVTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IErrorInfo* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IErrorInfo* _this);
    uint32_t (__stdcall *Release)(SWRT_IErrorInfo* _this);
    SWRT_HResult (__stdcall *GetGUID)(SWRT_IErrorInfo* _this, SWRT_Guid* guid);
    SWRT_HResult (__stdcall *GetSource)(SWRT_IErrorInfo* _this, SWRT_BStr* source);
    SWRT_HResult (__stdcall *GetDescription)(SWRT_IErrorInfo* _this, SWRT_BStr* description);
    SWRT_HResult (__stdcall *GetHelpFile)(SWRT_IErrorInfo* _this, SWRT_BStr* helpFile);
    SWRT_HResult (__stdcall *GetHelpContext)(SWRT_IErrorInfo* _this, uint32_t* helpContext);
};
