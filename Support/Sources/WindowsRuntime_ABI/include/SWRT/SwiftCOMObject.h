#pragma once

// A COM-compliant structure for bridging Swift objects into COM.
typedef struct SWRT_SwiftCOMObject {
    const void* virtualTable;
    void* swiftObject;
} SWRT_SwiftCOMObject;