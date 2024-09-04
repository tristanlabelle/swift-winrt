#pragma once

#include "SWRT/windows/oleauto.h"
#include "SWRT/windows/unknwn.h"

typedef struct SWRT_ILanguageExceptionErrorInfo {
    struct SWRT_ILanguageExceptionErrorInfo_VirtualTable* VirtualTable;
} SWRT_ILanguageExceptionErrorInfo;

struct SWRT_ILanguageExceptionErrorInfo_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_ILanguageExceptionErrorInfo* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_ILanguageExceptionErrorInfo* _this);
    uint32_t (__stdcall *Release)(SWRT_ILanguageExceptionErrorInfo* _this);
    SWRT_HResult (__stdcall *GetLanguageException)(SWRT_ILanguageExceptionErrorInfo* _this, SWRT_IUnknown** languageException);
};

typedef struct SWRT_ILanguageExceptionErrorInfo2 {
    struct SWRT_ILanguageExceptionErrorInfo2_VirtualTable* VirtualTable;
} SWRT_ILanguageExceptionErrorInfo2;

struct SWRT_ILanguageExceptionErrorInfo2_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_ILanguageExceptionErrorInfo2* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_ILanguageExceptionErrorInfo2* _this);
    uint32_t (__stdcall *Release)(SWRT_ILanguageExceptionErrorInfo2* _this);
    SWRT_HResult (__stdcall *GetLanguageException)(SWRT_ILanguageExceptionErrorInfo2* _this, SWRT_IUnknown** languageException);
    SWRT_HResult (__stdcall *GetPreviousLanguageExceptionErrorInfo)(SWRT_ILanguageExceptionErrorInfo2* _this, SWRT_ILanguageExceptionErrorInfo2** previousLanguageExceptionErrorInfo);
    SWRT_HResult (__stdcall *CapturePropagationContext)(SWRT_ILanguageExceptionErrorInfo2* _this, SWRT_IUnknown* languageException);
    SWRT_HResult (__stdcall *GetPropagationContextHead)(SWRT_ILanguageExceptionErrorInfo2* _this, SWRT_ILanguageExceptionErrorInfo2** propagatedLanguageExceptionErrorInfoHead);
};

typedef struct SWRT_IRestrictedErrorInfo {
    struct SWRT_IRestrictedErrorInfo_VirtualTable* VirtualTable;
} SWRT_IRestrictedErrorInfo;

struct SWRT_IRestrictedErrorInfo_VirtualTable {
    SWRT_HResult (__stdcall *QueryInterface)(SWRT_IRestrictedErrorInfo* _this, SWRT_Guid* riid, void** ppvObject);
    uint32_t (__stdcall *AddRef)(SWRT_IRestrictedErrorInfo* _this);
    uint32_t (__stdcall *Release)(SWRT_IRestrictedErrorInfo* _this);
    SWRT_HResult (__stdcall *GetErrorDetails)(SWRT_IRestrictedErrorInfo* _this, SWRT_BStr* description, SWRT_HResult* error, SWRT_BStr* restrictedDescription, SWRT_BStr* capabilitySid);
    SWRT_HResult (__stdcall *GetReference)(SWRT_IRestrictedErrorInfo* _this, SWRT_BStr* reference);
};
