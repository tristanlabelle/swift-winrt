#include "pch.h"
#include "Collections.h"
#include "Collections.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::Windows::Foundation::Collections::IIterable<int32_t> Collections::CreateIterable(array_view<int32_t const> values)
    {
        return winrt::single_threaded_vector(std::vector<int32_t>(values.begin(), values.end()));
    }
    winrt::Windows::Foundation::Collections::IVector<int32_t> Collections::CreateVector(array_view<int32_t const> values)
    {
        return winrt::single_threaded_vector(std::vector<int32_t>(values.begin(), values.end()));
    }
    com_array<int32_t> Collections::IterableToArray(winrt::Windows::Foundation::Collections::IIterable<int32_t> const& iterable)
    {
        std::vector<int32_t> result;
        for (auto iterator = iterable.First(); iterator.HasCurrent(); iterator.MoveNext())
            result.push_back(iterator.Current());
        return com_array<int32_t>(result);
    }
}
