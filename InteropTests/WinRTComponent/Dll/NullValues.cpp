#include "pch.h"
#include "NullValues.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct NullValues
    {
        static bool IsObjectNull(winrt::Windows::Foundation::IInspectable const& value) { return value == nullptr; }
        static bool IsInterfaceNull(winrt::WinRTComponent::IMinimalInterface const& value) { return value == nullptr; }
        static bool IsClassNull(winrt::WinRTComponent::MinimalClass const& value) { return value == nullptr; }
        static bool IsDelegateNull(winrt::WinRTComponent::MinimalDelegate const& value) { return value == nullptr; }
        static bool IsReferenceNull(winrt::Windows::Foundation::IReference<int32_t> const& value) { return value == nullptr; }
        static winrt::Windows::Foundation::IInspectable GetNullObject() { return nullptr; }
        static winrt::WinRTComponent::IMinimalInterface GetNullInterface() { return nullptr; }
        static winrt::WinRTComponent::MinimalClass GetNullClass() { return nullptr; }
        static winrt::WinRTComponent::MinimalDelegate GetNullDelegate() { return nullptr; }
        static winrt::Windows::Foundation::IReference<int32_t> GetNullReference() { return nullptr; }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct NullValues : NullValuesT<NullValues, implementation::NullValues>
    {
    };
}

#include "NullValues.g.cpp"