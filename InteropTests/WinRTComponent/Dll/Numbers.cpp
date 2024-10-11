#include "pch.h"
#include "Numbers.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Numbers
    {
        static bool Not(bool value) { return !value; }
        static uint8_t IncrementUInt8(uint8_t value) { return value + 1; }
        static int16_t IncrementInt16(int16_t value) { return value + 1; }
        static uint16_t IncrementUInt16(uint16_t value) { return value + 1; }
        static int32_t IncrementInt32(int32_t value) { return value + 1; }
        static uint32_t IncrementUInt32(uint32_t value) { return value + 1; }
        static int64_t IncrementInt64(int64_t value) { return value + 1; }
        static uint64_t IncrementUInt64(uint64_t value) { return value + 1; }
        static float NegateSingle(float value) { return -value; }
        static double NegateDouble(double value) { return -value; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Numbers : NumbersT<Numbers, implementation::Numbers>
    {
    };
}

#include "Numbers.g.cpp"