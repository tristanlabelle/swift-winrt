#pragma once

#include <stdint.h>

#define SWRT_COMEmbedding_OwnerFlags_Mask ((uintptr_t)1)
/// The owner object derives from COMEmbedderEx.
#define SWRT_COMEmbedding_OwnerFlags_Extended ((uintptr_t)1)

/// Allows Swift objects to expose a COM interface to COM clients.
/// This structure is embedded in a Swift reference-counted object,
/// where its pointer can be treated as a an ABI-compatible COM object
/// derived from IUnknown.
typedef struct SWRT_COMEmbedding {
    /// The IUnknown-based virtual table for the COM object.
    const void* virtualTable;

    /// A tagged Unmanaged<AnyObject> pointer to the Swift object that
    /// controls the lifetime of this structure, directly or indirectly.
    /// This object is retained and released by AddRef/Release calls.
    /// The least significant bits store SWRT_COMEmbeddingFlags.
    uintptr_t swiftOwnerAndFlags;
} SWRT_COMEmbedding;
