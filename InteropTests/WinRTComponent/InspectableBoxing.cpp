#include "pch.h"
#include "InspectableBoxing.h"
#include "InspectableBoxing.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::Windows::Foundation::IInspectable InspectableBoxing::BoxInt32(int32_t value)
    {
        return winrt::box_value(value);
    }
    int32_t InspectableBoxing::UnboxInt32(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<int32_t>(value);
    }
    winrt::Windows::Foundation::IInspectable InspectableBoxing::BoxString(hstring const& value)
    {
        return winrt::box_value(value);
    }
    hstring InspectableBoxing::UnboxString(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<hstring>(value);
    }
    winrt::Windows::Foundation::IInspectable InspectableBoxing::BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value)
    {
        return winrt::box_value(value);
    }
    winrt::WinRTComponent::MinimalEnum InspectableBoxing::UnboxMinimalEnum(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<winrt::WinRTComponent::MinimalEnum>(value);
    }
    winrt::Windows::Foundation::IInspectable InspectableBoxing::BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value)
    {
        return winrt::box_value(value);
    }
    winrt::WinRTComponent::MinimalStruct InspectableBoxing::UnboxMinimalStruct(winrt::Windows::Foundation::IInspectable const& value)
    {
        return winrt::unbox_value<winrt::WinRTComponent::MinimalStruct>(value);
    }
}
