#pragma once
#include "NullValues.g.h"

namespace winrt::TestComponent::implementation
{
    struct NullValues
    {
        NullValues() = default;

        static bool IsObjectNull(winrt::Windows::Foundation::IInspectable const& value);
        static bool IsInterfaceNull(winrt::TestComponent::IMinimalInterface const& value);
        static bool IsClassNull(winrt::TestComponent::MinimalClass const& value);
        static bool IsDelegateNull(winrt::TestComponent::MinimalDelegate const& value);
        static winrt::Windows::Foundation::IInspectable GetNullObject();
        static winrt::TestComponent::IMinimalInterface GetNullInterface();
        static winrt::TestComponent::MinimalClass GetNullClass();
        static winrt::TestComponent::MinimalDelegate GetNullDelegate();
    };
}
namespace winrt::TestComponent::factory_implementation
{
    struct NullValues : NullValuesT<NullValues, implementation::NullValues>
    {
    };
}
