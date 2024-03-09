#pragma once

#include <stdint.h>

// GUID
typedef struct SWRT_Guid {
    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t Data4[8];
} SWRT_Guid;