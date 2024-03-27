#include "pch.h"
#include "Boxing.h"
#include "Boxing.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::Windows::Foundation::IInspectable Boxing::BoxInt32(int32_t value)
    {
        return winrt::box_value(value);
    }
    int32_t Boxing::UnboxInt32(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<int32_t>(value);
    }
    winrt::Windows::Foundation::IInspectable Boxing::BoxString(hstring const& value)
    {
        return winrt::box_value(value);
    }
    hstring Boxing::UnboxString(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<hstring>(value);
    }
    winrt::Windows::Foundation::IInspectable Boxing::BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value)
    {
        return winrt::box_value(value);
    }
    winrt::WinRTComponent::MinimalEnum Boxing::UnboxMinimalEnum(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<winrt::WinRTComponent::MinimalEnum>(value);
    }
    winrt::Windows::Foundation::IInspectable Boxing::BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value)
    {
        return winrt::box_value(value);
    }
    winrt::WinRTComponent::MinimalStruct Boxing::UnboxMinimalStruct(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<winrt::WinRTComponent::MinimalStruct>(value);
    }
}
