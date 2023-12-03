#pragma once
#include "Arrays.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Arrays
    {
        Arrays() = default;

        static hstring GetLast(array_view<hstring const> value);
        static com_array<hstring> Make(hstring const& a, hstring const& b);
        static void Output(hstring const& a, hstring const& b, com_array<hstring>& array);
        static void SwapFirstLast(array_view<hstring> array);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Arrays : ArraysT<Arrays, implementation::Arrays>
    {
    };
}
