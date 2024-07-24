#include "SWRT/windows/oleauto.h"

#include <Windows.h>
#include <oleauto.h>

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