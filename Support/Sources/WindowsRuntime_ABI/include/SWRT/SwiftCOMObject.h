#pragma once

#include "SWRT/unknwn.h"

// A COM-compliant structure for bridging Swift objects into COM.
typedef struct SWRT_SwiftCOMObject {
    const struct SWRT_IUnknownVTable* comVirtualTable;
    void* swiftObject;
} SWRT_SwiftCOMObject;