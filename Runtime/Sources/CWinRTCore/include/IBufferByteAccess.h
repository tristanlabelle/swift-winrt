#pragma once

#include <robuffer.h>

#ifndef __cplusplus
EXTERN_C const IID IID_IBufferByteAccess;

typedef interface IBufferByteAccess IBufferByteAccess;

typedef struct IBufferByteAccessVtbl
{
    BEGIN_INTERFACE

    HRESULT (STDMETHODCALLTYPE* QueryInterface)(IBufferByteAccess* This,
        REFIID riid,
        void** ppvObject);
    ULONG (STDMETHODCALLTYPE* AddRef)(IBufferByteAccess* This);
    ULONG (STDMETHODCALLTYPE* Release)(IBufferByteAccess* This);
    HRESULT (STDMETHODCALLTYPE* Buffer)(IBufferByteAccess* This,
        BYTE** data);

    END_INTERFACE
} IBufferByteAccessVtbl;

interface IBufferByteAccess
{
    CONST_VTBL struct IBufferByteAccessVtbl* lpVtbl;
};
#endif