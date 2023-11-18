#include "pch.h"
#include "Numbers.h"
#include "Numbers.g.cpp"

namespace winrt::TestComponent::implementation
{
    bool Numbers::Not(bool value)
    {
        return !value;
    }
    uint8_t Numbers::IncrementUInt8(uint8_t value)
    {
        return value + 1;
    }
    int16_t Numbers::IncrementInt16(int16_t value)
    {
        return value + 1;
    }
    uint16_t Numbers::IncrementUInt16(uint16_t value)
    {
        return value + 1;
    }
    int32_t Numbers::IncrementInt32(int32_t value)
    {
        return value + 1;
    }
    uint32_t Numbers::IncrementUInt32(uint32_t value)
    {
        return value + 1;
    }
    int64_t Numbers::IncrementInt64(int64_t value)
    {
        return value + 1;
    }
    uint64_t Numbers::IncrementUInt64(uint64_t value)
    {
        return value + 1;
    }
    float Numbers::NegateSingle(float value)
    {
        return -value;
    }
    double Numbers::NegateDouble(double value)
    {
        return -value;
    }
}
