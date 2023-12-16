#pragma once
#include "Overloading.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Overloading
    {
        Overloading() = default;

        static int32_t Sum();
        static int32_t Sum(int32_t a);
        static int32_t Sum(int32_t a, int32_t b);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Overloading : OverloadingT<Overloading, implementation::Overloading>
    {
    };
}
