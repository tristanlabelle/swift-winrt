#pragma once

#include <combaseapi.h>

inline IID GetISwiftObjectIID() {
    IID iid = { 0x905A0FEF, 0xBC53, 0x11DF, { 0x8C, 0x49, 0x00, 0x1E, 0x4F, 0xC6, 0x86, 0xDA } };
    return iid;
}

typedef interface ISwiftObject ISwiftObject;

typedef struct ISwiftObjectVtbl
{
    BEGIN_INTERFACE

    HRESULT (STDMETHODCALLTYPE* QueryInterface)(ISwiftObject* This, REFIID riid, void** ppvObject);
    ULONG (STDMETHODCALLTYPE* AddRef)(ISwiftObject* This);
    ULONG (STDMETHODCALLTYPE* Release)(ISwiftObject* This);
    void* (STDMETHODCALLTYPE* GetSwiftObject)(ISwiftObject* This);

    END_INTERFACE
} ISwiftObjectVtbl;

interface ISwiftObject
{
    CONST_VTBL struct ISwiftObjectVtbl* lpVtbl;
};