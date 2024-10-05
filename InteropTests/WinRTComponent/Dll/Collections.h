#pragma once
#include "Collections.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Collections
    {
        Collections() = default;

        static winrt::Windows::Foundation::Collections::IIterable<int32_t> CreateIterable(array_view<int32_t const> values);
        static winrt::Windows::Foundation::Collections::IVector<int32_t> CreateVector(array_view<int32_t const> values);
        static com_array<int32_t> IterableToArray(winrt::Windows::Foundation::Collections::IIterable<int32_t> const& iterable);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Collections : CollectionsT<Collections, implementation::Collections>
    {
    };
}
