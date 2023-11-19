#include "pch.h"
#include "NullValues.h"
#include "NullValues.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    bool NullValues::IsObjectNull(winrt::Windows::Foundation::IInspectable const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsInterfaceNull(winrt::WinRTComponent::IMinimalInterface const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsClassNull(winrt::WinRTComponent::MinimalClass const& value)
    {
        return value == nullptr;
    }
    bool NullValues::IsDelegateNull(winrt::WinRTComponent::MinimalDelegate const& value)
    {
        return value == nullptr;
    }
    winrt::Windows::Foundation::IInspectable NullValues::GetNullObject()
    {
        return nullptr;
    }
    winrt::WinRTComponent::IMinimalInterface NullValues::GetNullInterface()
    {
        return nullptr;
    }
    winrt::WinRTComponent::MinimalClass NullValues::GetNullClass()
    {
        return nullptr;
    }
    winrt::WinRTComponent::MinimalDelegate NullValues::GetNullDelegate()
    {
        return nullptr;
    }
}
