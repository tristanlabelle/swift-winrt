#include "pch.h"
#include "NullValues.h"
#include "NullValues.g.cpp"

namespace winrt::TestComponent::implementation
{
    bool NullValues::IsObjectNull(winrt::Windows::Foundation::IInspectable const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsInterfaceNull(winrt::TestComponent::IMinimalInterface const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsClassNull(winrt::TestComponent::MinimalClass const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsDelegateNull(winrt::TestComponent::MinimalDelegate const& value)
    {
        return value == nullptr;
    }
    winrt::Windows::Foundation::IInspectable NullValues::GetNullObject()
    {
        return nullptr;
    }
    winrt::TestComponent::IMinimalInterface NullValues::GetNullInterface()
    {
        return nullptr;
    }
    winrt::TestComponent::MinimalClass NullValues::GetNullClass()
    {
        return nullptr;
    }
    winrt::TestComponent::MinimalDelegate NullValues::GetNullDelegate()
    {
        return nullptr;
    }
}
