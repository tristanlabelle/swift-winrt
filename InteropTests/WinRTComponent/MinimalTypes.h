#pragma once
#include "MinimalClass.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass>
    {
        MinimalClass() = default;

        void Method();
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass, implementation::MinimalClass>
    {
    };
}
