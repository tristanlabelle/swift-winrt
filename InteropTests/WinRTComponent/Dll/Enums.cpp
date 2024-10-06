#include "pch.h"
#include "Enums.h"
#include "Enums.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    boolean Enums::HasFlags(Flags value, Flags flags)
    {
        return (value & flags) == flags;
    }
}
