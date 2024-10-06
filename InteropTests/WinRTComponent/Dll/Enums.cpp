#include "pch.h"
#include "Enums.h"
#include "Enums.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    boolean Enums::HasFlag(Flags value, Flags flag)
    {
        return (value & flag) == flag;
    }
}
