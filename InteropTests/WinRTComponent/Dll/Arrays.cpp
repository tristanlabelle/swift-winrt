#include "pch.h"
#include "Arrays.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Arrays
    {
        static hstring GetLast(array_view<hstring const> value)
        {
            return value.back();
        }

        static com_array<hstring> Make(hstring const& a, hstring const& b)
        {
            return { a, b };
        }

        static void Output(hstring const& a, hstring const& b, com_array<hstring>& array)
        {
            array = { a, b };
        }

        static void SwapFirstLast(array_view<hstring> array)
        {
            std::swap(array.front(), array.back());
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Arrays : ArraysT<Arrays, implementation::Arrays>
    {
    };
}

#include "Arrays.g.cpp"