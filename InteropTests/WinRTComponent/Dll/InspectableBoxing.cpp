#include "pch.h"
#include "InspectableBoxing.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct InspectableBoxing
    {
        static winrt::Windows::Foundation::IInspectable BoxInt32(int32_t value)
        {
            return winrt::box_value(value);
        }

        static int32_t UnboxInt32(winrt::Windows::Foundation::IInspectable const& value)
        {
            return winrt::unbox_value<int32_t>(value);
        }

        static winrt::Windows::Foundation::IInspectable BoxString(hstring const& value)
        {
            return winrt::box_value(value);
        }

        static hstring UnboxString(winrt::Windows::Foundation::IInspectable const& value)
        {
            return winrt::unbox_value<hstring>(value);
        }

        static winrt::Windows::Foundation::IInspectable BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value)
        {
            return winrt::box_value(value);
        }

        static winrt::WinRTComponent::MinimalEnum UnboxMinimalEnum(winrt::Windows::Foundation::IInspectable const& value)
        {
            return winrt::unbox_value<winrt::WinRTComponent::MinimalEnum>(value);
        }

        static winrt::Windows::Foundation::IInspectable BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value)
        {
            return winrt::box_value(value);
        }

        static winrt::WinRTComponent::MinimalStruct UnboxMinimalStruct(winrt::Windows::Foundation::IInspectable const& value)
        {
            return winrt::unbox_value<winrt::WinRTComponent::MinimalStruct>(value);
        }

        static winrt::Windows::Foundation::IInspectable BoxMinimalDelegate(winrt::WinRTComponent::MinimalDelegate const& value)
        {
            return winrt::box_value(value);
        }

        static winrt::WinRTComponent::MinimalDelegate UnboxMinimalDelegate(winrt::Windows::Foundation::IInspectable const& value)
        {
            return winrt::unbox_value<winrt::WinRTComponent::MinimalDelegate>(value);
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct InspectableBoxing : InspectableBoxingT<InspectableBoxing, implementation::InspectableBoxing>
    {
    };
}

#include "InspectableBoxing.g.cpp"