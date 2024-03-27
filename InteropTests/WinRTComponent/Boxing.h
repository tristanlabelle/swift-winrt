#pragma once
#include "Boxing.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct Boxing
    {
        Boxing() = default;

        static winrt::Windows::Foundation::IInspectable BoxInt32(int32_t value);
        static int32_t UnboxInt32(winrt::Windows::Foundation::IInspectable const& value);
        static winrt::Windows::Foundation::IInspectable BoxString(hstring const& value);
        static hstring UnboxString(winrt::Windows::Foundation::IInspectable const& value);
        static winrt::Windows::Foundation::IInspectable BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value);
        static winrt::WinRTComponent::MinimalEnum UnboxMinimalEnum(winrt::Windows::Foundation::IInspectable const& value);
        static winrt::Windows::Foundation::IInspectable BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value);
        static winrt::WinRTComponent::MinimalStruct UnboxMinimalStruct(winrt::Windows::Foundation::IInspectable const& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct Boxing : BoxingT<Boxing, implementation::Boxing>
    {
    };
}
