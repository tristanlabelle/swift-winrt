#include "pch.h"
#include "Arrays.h"
#include "Arrays.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    hstring Arrays::GetLast(array_view<hstring const> value)
    {
        return value.back();
    }
    com_array<hstring> Arrays::Make(hstring const& a, hstring const& b)
    {
        return { a, b };
    }
    void Arrays::Output(hstring const& a, hstring const& b, com_array<hstring>& array)
    {
        array = { a, b };
    }
    void Arrays::SwapFirstLast(array_view<hstring> array)
    {
        std::swap(array.front(), array.back());
    }
}
