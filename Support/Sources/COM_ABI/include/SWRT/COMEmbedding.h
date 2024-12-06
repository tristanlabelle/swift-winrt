#pragma once

// Allows Swift objects to expose a COM interface to COM clients.
// This structure is embedded in a Swift reference-counted object,
// where its pointer can be treated as a an ABI-compatible COM object
// derived from IUnknown.
typedef struct SWRT_COMEmbedding {
    // The IUnknown-based virtual table for the COM object.
    const void* virtualTable;
    // The Unmanaged<AnyObject> pointer to the Swift object that embeds this structure.
    // This object is retained and released by AddRef/Release calls.
    void* swiftEmbedder;
} SWRT_COMEmbedding;