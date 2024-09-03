#pragma once

#include <stdbool.h>
#include "SWRT/windows/unknwn.h"
#include "SWRT/windows/restrictederrorinfo.h"
#include "SWRT/windows/winstring.h"

typedef enum {
    SWRT_RO_ERROR_REPORTING_NONE               = 0x00000000,
    SWRT_RO_ERROR_REPORTING_SUPPRESSEXCEPTIONS = 0x00000001,
    SWRT_RO_ERROR_REPORTING_FORCEEXCEPTIONS    = 0x00000002,
    SWRT_RO_ERROR_REPORTING_USESETERRORINFO    = 0x00000004,
    SWRT_RO_ERROR_REPORTING_SUPPRESSSETERRORINFO = 0x00000008,
} SWRT_RO_ERROR_REPORTING_FLAGS;

SWRT_HResult SWRT_GetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
SWRT_HResult SWRT_RoCaptureErrorContext(SWRT_HResult hr);
void SWRT_RoClearError();
void SWRT_RoFailFastWithErrorContext(SWRT_HResult hrError);
SWRT_HResult SWRT_RoGetErrorReportingFlags(uint32_t* pflags);
SWRT_HResult SWRT_RoGetMatchingRestrictedErrorInfo(SWRT_HResult hrIn, SWRT_IRestrictedErrorInfo** ppRestrictedErrorInfo);
bool SWRT_RoOriginateError(SWRT_HResult error, SWRT_HString message);
bool SWRT_RoOriginateErrorW(SWRT_HResult error, uint32_t cchMax, const char16_t* message);
bool SWRT_RoOriginateLanguageException(SWRT_HResult error, SWRT_HString message, SWRT_IUnknown* languageException);
SWRT_HResult SWRT_RoReportUnhandledError(SWRT_IRestrictedErrorInfo* pRestrictedErrorInfo);
SWRT_HResult SWRT_RoSetErrorReportingFlags(uint32_t flags);
SWRT_HResult SWRT_RoTransformError(SWRT_HResult oldError, SWRT_HResult newError, SWRT_HString message);
SWRT_HResult SWRT_SetRestrictedErrorInfo(SWRT_IRestrictedErrorInfo* pRestrictedErrorInfo);