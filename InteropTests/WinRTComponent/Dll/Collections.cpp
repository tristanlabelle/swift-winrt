#include "pch.h"
#include "Collections.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Collections
    {
        static winrt::Windows::Foundation::Collections::IIterable<int32_t> CreateIterable(array_view<int32_t const> values)
        {
            return winrt::single_threaded_vector(std::vector<int32_t>(values.begin(), values.end()));
        }

        static winrt::Windows::Foundation::Collections::IVector<int32_t> CreateVector(array_view<int32_t const> values)
        {
            return winrt::single_threaded_vector(std::vector<int32_t>(values.begin(), values.end()));
        }

        static com_array<int32_t> IterableToArray(winrt::Windows::Foundation::Collections::IIterable<int32_t> const& iterable)
        {
            std::vector<int32_t> result;
            for (auto iterator = iterable.First(); iterator.HasCurrent(); iterator.MoveNext())
                result.push_back(iterator.Current());
            return com_array<int32_t>(result);
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct Collections : CollectionsT<Collections, implementation::Collections>
    {
    };
}

#include "Collections.g.cpp"