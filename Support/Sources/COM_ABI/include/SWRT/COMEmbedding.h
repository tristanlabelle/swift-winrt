#pragma once

#include <stdint.h>

#define SWRT_COMEmbeddingFlags_Mask ((uintptr_t)3)
/// The implementer object is external to the embedder and stored separately in SWRT_COMEmbeddingEx.
#define SWRT_COMEmbeddingFlags_ExternalImplementer ((uintptr_t)1)
/// The implementer object implements IUnknown for QueryInterface.
#define SWRT_COMEmbeddingFlags_ExternalImplementerIsIUnknown ((uintptr_t)2)

/// Allows Swift objects to expose a COM interface to COM clients.
/// This structure is embedded in a Swift reference-counted object,
/// where its pointer can be treated as a an ABI-compatible COM object
/// derived from IUnknown.
typedef struct SWRT_COMEmbedding {
    /// The IUnknown-based virtual table for the COM object.
    const void* virtualTable;

    /// A tagged Unmanaged<AnyObject> pointer to the Swift object that embeds this structure.
    /// This object is retained and released by AddRef/Release calls.
    /// The least significant bits store SWRT_COMEmbeddingFlags.
    uintptr_t swiftEmbedderAndFlags;
} SWRT_COMEmbedding;

/// Extends SWRT_COMEmbedding by separating the embedder and implementer objects.
typedef struct SWRT_COMEmbeddingEx {
    /// The base SWRT_COMEmbedding structure, where the extended bit may be set to 1.
    SWRT_COMEmbedding base;

    /// An Unmanaged<AnyObject> pointer to the Swift object that implements the COM interface,
    /// with a retained reference to it.
    void* swiftImplementer_retained;
} SWRT_COMEmbeddingEx;