#pragma once

// A COM-compliant structure for bridging Swift objects into COM.
// This structure is embedded in a Swift reference-counted object
// and then passed as a pointer to COM clients.
// The COM code can treat it as an IUnknown-derived object,
// and calls can resolve the Swift object pointer from it.
typedef struct SWRT_SwiftCOMObject {
    const void* virtualTable;
    // The Unmanaged<AnyObject> pointer to the Swift object that embeds this structure.
    // This object is retained and released by AddRef/Release calls.
    void* swiftSelf;
} SWRT_SwiftCOMObject;