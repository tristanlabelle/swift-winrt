#include "pch.h"
#include "ReferenceBoxing.h"
#include "ReferenceBoxing.g.cpp"

namespace winrt::WinRTComponent::implementation
{
    winrt::Windows::Foundation::IReference<int32_t> ReferenceBoxing::BoxInt32(int32_t value)
    {
        return { value };
    }
    int32_t ReferenceBoxing::UnboxInt32(winrt::Windows::Foundation::IReference<int32_t> const& value)
    {
        if (value == nullptr) throw winrt::hresult_invalid_argument();
        return value.Value();
    }
    Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> ReferenceBoxing::BoxMinimalEnum(winrt::WinRTComponent::MinimalEnum const& value)
    {
        return { value };
    }
    winrt::WinRTComponent::MinimalEnum ReferenceBoxing::UnboxMinimalEnum(Windows::Foundation::IReference<winrt::WinRTComponent::MinimalEnum> const& value)
    {
        if (value == nullptr) throw winrt::hresult_invalid_argument();
        return value.Value();
    }
    Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> ReferenceBoxing::BoxMinimalStruct(winrt::WinRTComponent::MinimalStruct const& value)
    {
        return { value };
    }
    winrt::WinRTComponent::MinimalStruct ReferenceBoxing::UnboxMinimalStruct(Windows::Foundation::IReference<winrt::WinRTComponent::MinimalStruct> const& value)
    {
        if (value == nullptr) throw winrt::hresult_invalid_argument();
        return value.Value();
    }
}
