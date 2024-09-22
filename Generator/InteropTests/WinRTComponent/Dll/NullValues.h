#pragma once
#include "NullValues.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct NullValues
    {
        NullValues() = default;

        static bool IsObjectNull(winrt::Windows::Foundation::IInspectable const& value);
        static bool IsInterfaceNull(winrt::WinRTComponent::IMinimalInterface const& value);
        static bool IsClassNull(winrt::WinRTComponent::MinimalClass const& value);
        static bool IsDelegateNull(winrt::WinRTComponent::MinimalDelegate const& value);
        static bool IsReferenceNull(winrt::Windows::Foundation::IReference<int32_t> const& value);
        static winrt::Windows::Foundation::IInspectable GetNullObject();
        static winrt::WinRTComponent::IMinimalInterface GetNullInterface();
        static winrt::WinRTComponent::MinimalClass GetNullClass();
        static winrt::WinRTComponent::MinimalDelegate GetNullDelegate();
        static winrt::Windows::Foundation::IReference<int32_t> GetNullReference();
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct NullValues : NullValuesT<NullValues, implementation::NullValues>
    {
    };
}
