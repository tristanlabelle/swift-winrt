#pragma once
#include "ReferenceBoxing.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ReferenceBoxing
    {
        ReferenceBoxing() = default;

        static winrt::Windows::Foundation::IReference<int32_t> BoxInt32(int32_t value);
        static int32_t UnboxInt32(winrt::Windows::Foundation::IReference<int32_t> const& value);
        static winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value);
        static winrt::WinRTComponent::MinimalEnum UnboxMinimalEnum(winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> const& value);
        static winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value);
        static winrt::WinRTComponent::MinimalStruct UnboxMinimalStruct(winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> const& value);
    };
}
namespace winrt::WinRTComponent::factory_implementation
{
    struct ReferenceBoxing : ReferenceBoxingT<ReferenceBoxing, implementation::ReferenceBoxing>
    {
    };
}
