#pragma once
#include "MinimalClass.g.h"

namespace winrt::TestComponent::implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass>
    {
        MinimalClass() = default;

        void Method();
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct MinimalClass : MinimalClassT<MinimalClass, implementation::MinimalClass>
    {
    };
}
