#pragma once
#include "Enums.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Enums
    {
        Enums() = default;

        static boolean HasFlag(Flags value, Flags flag);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Enums : EnumsT<Enums, implementation::Enums>
    {
    };
}
