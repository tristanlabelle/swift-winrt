#include "pch.h"
#include "ReferenceBoxing.g.h"

namespace winrt::WinRTComponent::implementation
{
    struct ReferenceBoxing
    {
        static winrt::Windows::Foundation::IReference<int32_t> BoxInt32(int32_t value)
        {
            return { value };
        }

        static int32_t UnboxInt32(winrt::Windows::Foundation::IReference<int32_t> const& value)
        {
            if (value == nullptr) throw winrt::hresult_invalid_argument();
            return value.Value();
        }

        static winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value)
        {
            return { value };
        }

        static winrt::WinRTComponent::MinimalEnum UnboxMinimalEnum(winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> const& value)
        {
            if (value == nullptr) throw winrt::hresult_invalid_argument();
            return value.Value();
        }

        static winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value)
        {
            return { value };
        }

        static winrt::WinRTComponent::MinimalStruct UnboxMinimalStruct(winrt::Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> const& value)
        {
            if (value == nullptr) throw winrt::hresult_invalid_argument();
            return value.Value();
        }
    };
}

namespace winrt::WinRTComponent::factory_implementation
{
    struct ReferenceBoxing : ReferenceBoxingT<ReferenceBoxing, implementation::ReferenceBoxing>
    {
    };
}

#include "ReferenceBoxing.g.cpp"