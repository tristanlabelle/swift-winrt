#include "SWRT/windows/oleauto.h"

#include <Windows.h>
#include <oleauto.h>

SWRT_HResult SWRT_GetErrorInfo(uint32_t dwReserved, SWRT_IErrorInfo** pperrinfo) {
    return (SWRT_HResult)GetErrorInfo(dwReserved, (IErrorInfo**)pperrinfo);
}

SWRT_HResult SWRT_SetErrorInfo(uint32_t dwReserved, SWRT_IErrorInfo* perrinfo) {
    return (SWRT_HResult)SetErrorInfo(dwReserved, (IErrorInfo*)perrinfo);
}

SWRT_BStr SWRT_SysAllocString(const char16_t* strIn) {
    return (SWRT_BStr)SysAllocString((const OLECHAR*)strIn);
}

SWRT_BStr SWRT_SysAllocStringLen(const char16_t* strIn, uint32_t ui) {
    return (SWRT_BStr)SysAllocStringLen((const OLECHAR*)strIn, (UINT)ui);
}

void SWRT_SysFreeString(SWRT_BStr bstrString) {
    SysFreeString((BSTR)bstrString);
}

uint32_t SWRT_SysStringLen(SWRT_BStr pbstr) {
    return (uint32_t)SysStringLen((BSTR)pbstr);
}