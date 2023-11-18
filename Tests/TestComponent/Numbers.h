#pragma once
#include "Numbers.g.h"

namespace winrt::TestComponent::implementation
{
    struct Numbers
    {
        Numbers() = default;

        static bool Not(bool value);
        static uint8_t IncrementUInt8(uint8_t value);
        static int16_t IncrementInt16(int16_t value);
        static uint16_t IncrementUInt16(uint16_t value);
        static int32_t IncrementInt32(int32_t value);
        static uint32_t IncrementUInt32(uint32_t value);
        static int64_t IncrementInt64(int64_t value);
        static uint64_t IncrementUInt64(uint64_t value);
        static float NegateSingle(float value);
        static double NegateDouble(double value);
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct Numbers : NumbersT<Numbers, implementation::Numbers>
    {
    };
}
